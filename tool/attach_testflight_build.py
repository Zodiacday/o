#!/usr/bin/env python3
"""Make a processed App Store Connect build available to an internal group.

This deliberately does not create groups or invite testers. Those are one-time
account changes. Once a project has an internal group with the intended tester,
this script makes each CI upload available to that group and is safe to rerun.
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from typing import Any

import jwt
import requests


API_ROOT = "https://api.appstoreconnect.apple.com/v1"
READY_STATE = "VALID"
TERMINAL_FAILURE_STATES = {"INVALID", "FAILED"}


def required_env(*names: str) -> str:
    for name in names:
        value = os.environ.get(name)
        if value:
            return value
    raise RuntimeError(f"Missing required GitHub secret/environment variable: {' or '.join(names)}")


def auth_headers() -> dict[str, str]:
    key_id = required_env("APP_STORE_CONNECT_KEY_ID", "ASC_KEY_ID")
    issuer_id = required_env("APP_STORE_CONNECT_ISSUER_ID", "ASC_ISSUER_ID")
    private_key = required_env("APP_STORE_CONNECT_PRIVATE_KEY", "ASC_PRIVATE_KEY")
    private_key = private_key.replace("\\n", "\n").replace("\r\n", "\n")

    now = int(time.time())
    token = jwt.encode(
        {
            "iss": issuer_id,
            "iat": now,
            "exp": now + 15 * 60,
            "aud": "appstoreconnect-v1",
        },
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


def api_request(
    method: str,
    path: str,
    headers: dict[str, str],
    *,
    params: dict[str, str] | None = None,
    body: dict[str, Any] | None = None,
) -> Any:
    response = requests.request(
        method,
        f"{API_ROOT}{path}",
        headers=headers,
        params=params,
        json=body,
        timeout=45,
    )
    if response.status_code == 204:
        return None
    if not response.ok:
        detail = response.text.strip() or response.reason
        raise RuntimeError(f"App Store Connect API {method} {path} failed ({response.status_code}): {detail}")
    try:
        return response.json()
    except ValueError as exc:
        raise RuntimeError(f"App Store Connect API returned invalid JSON for {method} {path}") from exc


def find_processed_build(
    app_id: str,
    build_number: str,
    headers: dict[str, str],
    timeout_seconds: int,
    poll_seconds: int,
) -> tuple[str, dict[str, Any]]:
    deadline = time.monotonic() + timeout_seconds
    while True:
        payload = api_request(
            "GET",
            "/builds",
            headers,
            params={
                "filter[app]": app_id,
                "filter[version]": build_number,
                "sort": "-uploadedDate",
                "limit": "200",
            },
        )
        builds = payload.get("data", []) if isinstance(payload, dict) else []
        if builds:
            build = builds[0]
            build_id = build.get("id")
            attributes = build.get("attributes") or {}
            state = attributes.get("processingState")
            if build_id and state == READY_STATE:
                print(f"Apple processing complete: build {build_number} is VALID.")
                return build_id, attributes
            if state in TERMINAL_FAILURE_STATES:
                raise RuntimeError(
                    f"Apple rejected build {build_number} with processing state {state}."
                )
            print(
                f"Waiting for Apple processing: build {build_number} is {state or 'not visible yet'}...",
                flush=True,
            )
        else:
            print(f"Waiting for Apple to register build {build_number}...", flush=True)

        if time.monotonic() >= deadline:
            raise TimeoutError(
                f"Timed out waiting for build {build_number} to finish Apple processing."
            )
        time.sleep(poll_seconds)


def find_internal_group(
    app_id: str, group_name: str, headers: dict[str, str]
) -> tuple[str, dict[str, Any]]:
    payload = api_request(
        "GET",
        f"/apps/{app_id}/betaGroups",
        headers,
        params={
            "limit": "200",
            "fields[betaGroups]": "name,isInternalGroup,hasAccessToAllBuilds",
        },
    )
    groups = payload.get("data", []) if isinstance(payload, dict) else []
    matches = [
        group
        for group in groups
        if (group.get("attributes") or {}).get("name") == group_name
        and (group.get("attributes") or {}).get("isInternalGroup") is True
    ]
    if not matches:
        raise RuntimeError(
            f'No internal TestFlight group named "{group_name}" exists for App Store Connect app {app_id}. '
            "Create the group and add your Apple Account once, then rerun the workflow."
        )
    if len(matches) > 1:
        raise RuntimeError(
            f'Multiple internal TestFlight groups are named "{group_name}" for app {app_id}. '
            "Rename one of them so CI can target exactly one group."
        )
    group = matches[0]
    return group["id"], group.get("attributes") or {}


def group_build_ids(group_id: str, headers: dict[str, str]) -> set[str]:
    payload = api_request(
        "GET",
        f"/betaGroups/{group_id}/relationships/builds",
        headers,
        params={"limit": "200"},
    )
    return {
        item.get("id")
        for item in (payload or {}).get("data", [])
        if item.get("id")
    }


def attach_build(group_id: str, build_id: str, headers: dict[str, str]) -> bool:
    existing = group_build_ids(group_id, headers)
    if build_id in existing:
        return False
    try:
        api_request(
            "POST",
            f"/betaGroups/{group_id}/relationships/builds",
            headers,
            body={"data": [{"type": "builds", "id": build_id}]},
        )
    except RuntimeError as exc:
        # A duplicate relationship can race with another workflow. Confirm the
        # final state before turning that harmless race into a failure.
        if build_id not in group_build_ids(group_id, headers):
            raise exc
        return False
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Wait for a processed App Store Connect build and add it to an internal TestFlight group."
    )
    parser.add_argument("--app-id", required=True, help="App Store Connect app ID")
    parser.add_argument("--build-number", required=True, help="CFBundleVersion uploaded by this workflow")
    parser.add_argument("--group-name", default="Internal", help="Exact internal TestFlight group name")
    parser.add_argument("--timeout-seconds", type=int, default=30 * 60)
    parser.add_argument("--poll-seconds", type=int, default=20)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.timeout_seconds <= 0 or args.poll_seconds <= 0:
        raise ValueError("--timeout-seconds and --poll-seconds must be positive")

    headers = auth_headers()
    build_id, attributes = find_processed_build(
        args.app_id,
        args.build_number,
        headers,
        args.timeout_seconds,
        args.poll_seconds,
    )
    group_id, group_attributes = find_internal_group(args.app_id, args.group_name, headers)

    if group_attributes.get("hasAccessToAllBuilds") is True:
        print(
            f'TestFlight group "{args.group_name}" has automatic build access; '
            f"build {attributes.get('version', args.build_number)} is available to its testers."
        )
        return 0

    attached = attach_build(group_id, build_id, headers)
    if attached:
        print(
            f'TestFlight: build {attributes.get("version", args.build_number)} '
            f'attached to internal group "{args.group_name}".'
        )
    else:
        print(
            f'TestFlight: build {attributes.get("version", args.build_number)} '
            f'was already available in internal group "{args.group_name}".'
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, TimeoutError, ValueError) as exc:
        print(f"::error::{exc}", file=sys.stderr)
        raise SystemExit(1)
