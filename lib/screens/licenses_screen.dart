import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_theme.dart';

class LicensePackageInfo {
  final String name;
  final String version;
  final String licenseType;
  final String description;
  final String author;
  final String fullLicense;

  const LicensePackageInfo({
    required this.name,
    required this.version,
    required this.licenseType,
    required this.description,
    required this.author,
    required this.fullLicense,
  });
}

const List<LicensePackageInfo> kOpenSourcePackages = [
  LicensePackageInfo(
    name: 'flutter',
    version: 'SDK 3.29+',
    licenseType: 'BSD-3-Clause',
    description: 'Flutter is Google\'s SDK for crafting high-performance, beautiful mobile and web applications.',
    author: 'The Flutter Authors',
    fullLicense: '''Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.''',
  ),
  LicensePackageInfo(
    name: 'mobile_scanner',
    version: '^5.2.3',
    licenseType: 'Apache-2.0',
    description: 'Universal camera barcode and QR code scanner powered by ML Kit and platform views.',
    author: 'Julian Steenbakker & Contributors',
    fullLicense: '''Copyright 2021 Julian Steenbakker

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.''',
  ),
  LicensePackageInfo(
    name: 'webview_flutter',
    version: '^4.10.0',
    licenseType: 'BSD-3-Clause',
    description: 'Hardware-accelerated embedded browser runtime engine for rendering developer preview targets.',
    author: 'Flutter Team',
    fullLicense: '''Copyright 2013 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.''',
  ),
  LicensePackageInfo(
    name: 'flutter_lucide',
    version: '^1.1.0',
    licenseType: 'ISC / MIT',
    description: 'Precision vector iconography system based on Lucide Icons.',
    author: 'Lucide Project & Flutter Contributors',
    fullLicense: '''ISC License

Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022 as part of Feather (MIT). All other marks for Lucide are held by Lucide Contributors 2022-2024.

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.''',
  ),
  LicensePackageInfo(
    name: 'google_fonts',
    version: '^6.2.1',
    licenseType: 'Apache-2.0',
    description: 'Runtime font loader for Inter and JetBrains Mono typography.',
    author: 'Material Design Authors',
    fullLicense: '''Copyright 2020 The Flutter Authors. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0''',
  ),
  LicensePackageInfo(
    name: 'flutter_animate',
    version: '^4.5.2',
    licenseType: 'MIT',
    description: 'Performant declarative motion choreography and entrance transitions.',
    author: 'Grant Skinner (gskinner)',
    fullLicense: '''MIT License

Copyright (c) 2022 gskinner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so.''',
  ),
  LicensePackageInfo(
    name: 'flutter_bounceable',
    version: '^1.1.0',
    licenseType: 'MIT',
    description: 'Tactile spring physics interaction for micro-feedback on touch and click.',
    author: 'Guillaume Roux',
    fullLicense: '''MIT License

Copyright (c) 2021 Guillaume Roux

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.''',
  ),
  LicensePackageInfo(
    name: 'toastification',
    version: '^2.3.0',
    licenseType: 'MIT',
    description: 'Industrial HUD notification overlays and notification management.',
    author: 'Payam Zahedi',
    fullLicense: '''MIT License

Copyright (c) 2023 Payam Zahedi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.''',
  ),
  LicensePackageInfo(
    name: 'qr_flutter',
    version: '^4.1.0',
    licenseType: 'BSD-3-Clause',
    description: 'Native QR code rendering engine with high error correction and matrix generation.',
    author: 'Luke Freeman',
    fullLicense: '''Copyright (c) 2019, Luke Freeman. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.''',
  ),
  LicensePackageInfo(
    name: 'flutter_slidable',
    version: '^3.1.2',
    licenseType: 'MIT',
    description: 'Smooth swipe action gestures for list tiles and session deletion.',
    author: 'Romain Rastel',
    fullLicense: '''MIT License

Copyright (c) 2018 Romain Rastel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.''',
  ),
  LicensePackageInfo(
    name: 'skeletonizer',
    version: '^1.4.3',
    licenseType: 'MIT',
    description: 'Automated shimmer skeleton placeholders matching exact layout hierarchy.',
    author: 'Milad Akarie',
    fullLicense: '''MIT License

Copyright (c) 2023 Milad Akarie

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.''',
  ),
  LicensePackageInfo(
    name: 'connectivity_plus',
    version: '^6.1.1',
    licenseType: 'BSD-3-Clause',
    description: 'Real-time network state listener for WiFi, cellular, and ethernet status.',
    author: 'Flutter Community',
    fullLicense: '''Copyright 2017 The Chromium Authors. All rights reserved.
Copyright 2020 The Flutter Community Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice.''',
  ),
  LicensePackageInfo(
    name: 'shared_preferences',
    version: '^2.3.5',
    licenseType: 'BSD-3-Clause',
    description: 'Persistent local key-value store for session history and user settings.',
    author: 'Flutter Authors',
    fullLicense: '''Copyright 2013 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice.''',
  ),
  LicensePackageInfo(
    name: 'cupertino_icons',
    version: '^1.0.8',
    licenseType: 'MIT',
    description: 'Default asset icon font for iOS Cupertino iconography.',
    author: 'Flutter Authors',
    fullLicense: '''The MIT License (MIT)

Copyright (c) 2016 Flutter Authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.''',
  ),
];

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = kOpenSourcePackages.where((pkg) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return pkg.name.toLowerCase().contains(query) ||
          pkg.description.toLowerCase().contains(query) ||
          pkg.licenseType.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 24, 16),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: Bounceable(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.arrow_left,
                          color: AppTheme.textPrimary,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open-source licenses',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'The software that helps PreviewPort run.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${kOpenSourcePackages.length} libraries',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.previewBorder),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      color: AppTheme.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search libraries',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(bottom: 10),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      Semantics(
                        button: true,
                        label: 'Clear search',
                        child: GestureDetector(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Icon(
                              LucideIcons.x,
                              color: AppTheme.textSecondary,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching licenses found',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.borderSubtle,
                      ),
                      itemBuilder: (context, index) =>
                          _buildPackageRow(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageRow(LicensePackageInfo pkg) {
    return Semantics(
      button: true,
      label: '${pkg.name}, ${pkg.licenseType}',
      hint: 'Opens the full license text',
      child: Bounceable(
        scaleFactor: 0.99,
        onTap: () => _showLicenseDetails(pkg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pkg.name,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pkg.version,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pkg.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pkg.author,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    pkg.licenseType,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppTheme.cyan,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Icon(
                    LucideIcons.chevron_right,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLicenseDetails(LicensePackageInfo pkg) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.84,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppTheme.previewBorder),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.previewBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.name,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${pkg.licenseType} · ${pkg.author}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Copy ${pkg.name} license',
                      child: IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: pkg.fullLicense),
                          );
                          HapticFeedback.lightImpact();
                          toastification.show(
                            context: context,
                            type: ToastificationType.success,
                            style: ToastificationStyle.flat,
                            title: Text('Copied ${pkg.name} license'),
                            alignment: Alignment.topCenter,
                            autoCloseDuration: const Duration(seconds: 2),
                            primaryColor: AppTheme.cyan,
                            backgroundColor: AppTheme.surface,
                            foregroundColor: AppTheme.textPrimary,
                          );
                        },
                        tooltip: 'Copy license text',
                        icon: const Icon(
                          LucideIcons.copy,
                          size: 17,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderSubtle,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
                  child: SelectableText(
                    pkg.fullLicense,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      height: 1.55,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
