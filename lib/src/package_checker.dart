import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:pana/pana.dart';
import 'package:path/path.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/dependency_checker.dart';

/// Represents the config of the package we are checking dependencies for.
class PackageChecker {
  /// Add dependent packages
  final List<DependencyChecker> packages;

  /// The pubspec config for the package
  final Pubspec pubspec;

  /// The liscense checker config. Includes permitted licenses and approved packages.
  final Config config;

  PackageChecker._({
    required this.pubspec,
    required this.packages,
    required this.config,
  });

  /// Creates a package checker by checking the directory for a pubspec.yaml
  /// and a package_config.json file.
  static Future<PackageChecker> fromDirectory({
    required Directory directory,
    required Config config,
  }) async {
    File pubspecFile = File(join(directory.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return throw FileSystemException(
        'pubspec.yaml file not found in current directory.',
      );
    }
    Pubspec pubspec = Pubspec.parseYaml(await pubspecFile.readAsString());
    PackageConfig? packageConfig =
        await findPackageConfig(directory, recurse: false);

    if (packageConfig == null) {
      throw FileSystemException(
        'No package_config.json found. Are you sure this is a Dart package directory?',
      );
    }
    List<DependencyChecker> packageDependencies = [];

    for (Package pkg in packageConfig.packages) {
      if (pkg.name == pubspec.name) {
        // Don't add or check self
        continue;
      }
      packageDependencies.add(DependencyChecker(config: config, package: pkg));
    }

    return PackageChecker._(
      pubspec: pubspec,
      packages: packageDependencies,
      config: config,
    );
  }

  /// Creates a package checker by checking the current directory for a pubspec.yaml
  /// and a package_config.json file.
  static Future<PackageChecker> fromCurrentDirectory({
    required Config config,
  }) async {
    return fromDirectory(
      directory: Directory.current,
      config: config,
    );
  }
}
