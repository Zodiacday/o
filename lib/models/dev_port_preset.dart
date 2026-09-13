import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class DevPortPreset {
  final int port;
  final String framework;
  final String description;
  final IconData icon;
  final bool isHttps;
  final bool isCustom;

  const DevPortPreset({
    required this.port,
    required this.framework,
    required this.description,
    required this.icon,
    this.isHttps = false,
    this.isCustom = false,
  });

  DevPortPreset copyWith({
    int? port,
    String? framework,
    String? description,
    IconData? icon,
    bool? isHttps,
    bool? isCustom,
  }) {
    return DevPortPreset(
      port: port ?? this.port,
      framework: framework ?? this.framework,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isHttps: isHttps ?? this.isHttps,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'port': port,
    'framework': framework,
    'description': description,
    'isHttps': isHttps,
    'isCustom': isCustom,
  };

  factory DevPortPreset.fromJson(Map<String, dynamic> json) {
    final port = json['port'] as int? ?? 3000;
    final isHttps = json['isHttps'] as bool? ?? false;
    final isCustom = json['isCustom'] as bool? ?? true;
    final framework = json['framework'] as String?;
    final description = json['description'] as String?;

    final signature = DevPortPreset.fromPortAndSignature(
      port,
      fallbackTitle: framework,
      isHttps: isHttps,
      isCustom: isCustom,
    );

    return DevPortPreset(
      port: port,
      framework: (framework != null && framework.trim().isNotEmpty)
          ? framework
          : signature.framework,
      description: (description != null && description.trim().isNotEmpty)
          ? description
          : signature.description,
      icon: signature.icon,
      isHttps: isHttps,
      isCustom: isCustom,
    );
  }

  static DevPortPreset fromPortAndSignature(
    int port, {
    String? fallbackTitle,
    bool isHttps = false,
    bool isCustom = false,
  }) {
    switch (port) {
      case 5173:
        return DevPortPreset(
          port: port,
          framework: 'Vite / Astro',
          description: 'Vue, Svelte, React',
          icon: PhosphorIconsRegular.lightning,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 3000:
        return DevPortPreset(
          port: port,
          framework: 'Next.js',
          description: 'React, Remix, Node',
          icon: PhosphorIconsRegular.code,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8080:
        return DevPortPreset(
          port: port,
          framework: 'Flutter Web',
          description: 'PreviewPort, Spring',
          icon: PhosphorIconsRegular.deviceMobile,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8000:
        return DevPortPreset(
          port: port,
          framework: 'FastAPI / API',
          description: 'Python, Flask, Rails',
          icon: PhosphorIconsRegular.terminalWindow,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 4200:
        return DevPortPreset(
          port: port,
          framework: 'Angular',
          description: 'Angular CLI, RxJS',
          icon: PhosphorIconsRegular.browsers,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8081:
        return DevPortPreset(
          port: port,
          framework: 'React Native',
          description: 'Metro Bundler',
          icon: PhosphorIconsRegular.deviceMobile,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 5000:
        return DevPortPreset(
          port: port,
          framework: 'Flask / API',
          description: 'Python Web API',
          icon: PhosphorIconsRegular.terminalWindow,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 1234:
        return DevPortPreset(
          port: port,
          framework: 'Parcel',
          description: 'Zero-config bundler',
          icon: PhosphorIconsRegular.package,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8888:
        return DevPortPreset(
          port: port,
          framework: 'Jupyter / MAMP',
          description: 'Notebooks, PHP',
          icon: PhosphorIconsRegular.browsers,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      default:
        return DevPortPreset(
          port: port,
          framework: (fallbackTitle != null && fallbackTitle.trim().isNotEmpty)
              ? fallbackTitle.trim()
              : 'Port $port',
          description: 'Local Dev Server',
          icon: PhosphorIconsRegular.terminalWindow,
          isHttps: isHttps,
          isCustom: isCustom,
        );
    }
  }
}
