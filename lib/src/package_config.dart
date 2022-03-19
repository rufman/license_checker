import 'dart:convert';
import 'dart:io';

import 'package:pana/pana.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/package.dart';

/// Represents the config of the package we are checking dependencies for.
class PackageConfig {
  /// Add dependent packages
  final List<Package> packages;

  /// The pubspec config for the package
  final Pubspec pubspec;

  /// The liscense checker config. Includes permitted licenses and approved packages.
  final Config config;

  /// Constructor for package config
  PackageConfig({
    required this.pubspec,
    required this.packages,
    required this.config,
  });

  PackageConfig._({
    required this.pubspec,
    required this.packages,
    required this.config,
  });

  /// Constructs a package config from json
  factory PackageConfig.fromJson({
    required Pubspec pubspec,
    required Config config,
    required Object source,
  }) {
    List<Package> packages = [];
    if (source is! Map) {
      throw FormatException();
    }
    Object packagesSource = source['packages'] as Object? ?? [];
    if (packagesSource is! List) {
      throw FormatException();
    }
    for (Object p in packagesSource) {
      Package pkg = Package.fromJson(config: config, source: p);
      if (pkg.name == pubspec.name) {
        // Don't add or check self
        continue;
      }
      packages.add(pkg);
    }

    return PackageConfig._(
      pubspec: pubspec,
      packages: packages,
      config: config,
    );
  }

  /// Creates a package config from a file. Throws an error if the format is incorrect.
  factory PackageConfig.fromFile({
    required File pubspecFile,
    required File packageConfigFile,
    required Config config,
  }) {
    if (!pubspecFile.existsSync()) {
      return throw FileSystemException(
        'pubspec.yaml file not found in current directory.',
      );
    }

    if (!packageConfigFile.existsSync()) {
      return throw FileSystemException(
        '.dart_tool/package_config.json file not found in current directory. You may need to run "flutter pub get" or "dart pub get".',
      );
    }

    return PackageConfig.fromJson(
      pubspec: Pubspec.parseYaml(pubspecFile.readAsStringSync()),
      config: config,
      source: json.decode(packageConfigFile.readAsStringSync()),
    );
  }
}
