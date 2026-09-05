import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';

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
      final q = _searchQuery.toLowerCase();
      return pkg.name.toLowerCase().contains(q) ||
          pkg.description.toLowerCase().contains(q) ||
          pkg.licenseType.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF000000),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF1E2638),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Bounceable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1E2638),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.arrow_left,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open Source Licenses',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Core engine dependencies & libraries',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${kOpenSourcePackages.length} PKGS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF000000),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF1E2638),
                    width: 0.5,
                  ),
                ),
              ),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1E2638),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      color: Color(0xFF64748B),
                      size: 15,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search packages by name or license...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: const Icon(
                          LucideIcons.x,
                          color: Color(0xFF94A3B8),
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Packages List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.package_open,
                            color: Color(0xFF475569),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No matching licenses found',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final pkg = filtered[index];
                        return _buildPackageCard(pkg);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(LicensePackageInfo pkg) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pkg.name,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pkg.version,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pkg.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFF1E2638),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    pkg.licenseType,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF141A26),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pkg.author,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                  ),
                ),
                Bounceable(
                  onTap: () => _showLicenseDetails(pkg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Read Agreement',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevron_right,
                        size: 12,
                        color: Color(0xFF00E5FF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenseDetails(LicensePackageInfo pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: Color(0xFF1E2638), width: 1),
            left: BorderSide(color: Color(0xFF1E2638), width: 1),
            right: BorderSide(color: Color(0xFF1E2638), width: 1),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2638),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pkg.licenseType} License · ${pkg.author}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Bounceable(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: pkg.fullLicense));
                      toastification.show(
                        context: context,
                        type: ToastificationType.success,
                        style: ToastificationStyle.flat,
                        title: Text('Copied ${pkg.name} license'),
                        alignment: Alignment.topCenter,
                        autoCloseDuration: const Duration(seconds: 2),
                        primaryColor: const Color(0xFF00E5FF),
                        backgroundColor: const Color(0xFF000000),
                        foregroundColor: Colors.white,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF1E2638),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.copy,
                            size: 13,
                            color: Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Copy Text',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF141A26),
            ),
            // Text area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05070B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1E2638),
                      width: 1,
                    ),
                  ),
                  child: SelectableText(
                    pkg.fullLicense,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFFCBD5E1),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
