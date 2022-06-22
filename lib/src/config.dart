import 'dart:io';

import 'package:yaml/yaml.dart';

/// Represents the config parsed from a config file for the license checker.
class Config {
  /// List of permitted license.
  final List<String> permittedLicenses;

  /// List of licenses that are not allowed to be used by default.
  final List<String> rejectedLicenses;

  /// Packages by license that have been explicitly approved.
  final Map<String, List<String>> approvedPackages;

  /// Map to override copyright notices for packages, if they are not parsed correctly.
  final Map<String, String> copyrightNotice;

  /// Map to override licenses for packages, if they are not parsed correctly.
  final Map<String, String> packageLicenseOverride;

  Config._({
    required this.permittedLicenses,
    required this.rejectedLicenses,
    required this.approvedPackages,
    required this.copyrightNotice,
    required this.packageLicenseOverride,
  });

  /// Parses and creates config from a file
  factory Config.fromFile(File configFile) {
    if (!configFile.existsSync()) {
      return throw FileSystemException(
        '${configFile.path} file not found in current directory.',
      );
    }

    YamlMap config = loadYaml(configFile.readAsStringSync());

    Object? permittedLicenses = config['permittedLicenses'];
    Object? rejectedLicenses = config['rejectedLicenses'];
    Object? approvedPackages = config['approvedPackages'];
    Object? copyrightNotice = config['copyrightNotice'];
    Object? packageLicenseOverride = config['packageLicenseOverride'];
    if (permittedLicenses == null) {
      return throw FormatException('`permittedLicenses` not defined');
    }
    if (permittedLicenses is! List) {
      return throw FormatException(
        '`permittedLicenses` is not defined as a list',
      );
    }
    if (rejectedLicenses != null && rejectedLicenses is! List) {
      return throw FormatException(
        '`rejectedLicenses` is not defined as a list',
      );
    }

    List<String> stringRejectLicenses = [];
    List<String> stringLicenses =
        permittedLicenses.whereType<String>().toList();
    if (rejectedLicenses != null && rejectedLicenses is List) {
      stringRejectLicenses = rejectedLicenses.whereType<String>().toList();
    }

    Map<String, List<String>> checkedApprovedPackages = {};
    if (approvedPackages != null) {
      if (approvedPackages is! Map) {
        return throw FormatException('`approvedPackages` not defined as a map');
      }
      for (MapEntry<dynamic, dynamic> entry in approvedPackages.entries) {
        Object license = entry.key;
        Object packages = entry.value;
        if (license is! String) {
          return throw FormatException(
            '`approvedPackages` must be keyed by a string license name',
          );
        }
        if (packages is! List) {
          return throw FormatException(
            '`approvedPackages` value must specified as a list',
          );
        }

        List<String> stringApprovedPackages =
            packages.whereType<String>().toList();

        checkedApprovedPackages[license] = stringApprovedPackages;
      }
    }
    Map<String, String> checkedCopyrightNotice =
        _checkStringMap(copyrightNotice, 'copyrightNotice');

    Map<String, String> checkedPackageLicenseOverride =
        _checkStringMap(packageLicenseOverride, 'packageLicenseOverride');

    return Config._(
      permittedLicenses: stringLicenses,
      approvedPackages: checkedApprovedPackages,
      rejectedLicenses: stringRejectLicenses,
      copyrightNotice: checkedCopyrightNotice,
      packageLicenseOverride: checkedPackageLicenseOverride,
    );
  }
}

Map<String, String> _checkStringMap(Object? map, String variableName) {
  Map<String, String> checkedMap = {};
  if (map != null) {
    if (map is! Map) {
      return throw FormatException('`$variableName` not defined as a map');
    }
    for (MapEntry<dynamic, dynamic> entry in map.entries) {
      Object mapKey = entry.key;
      Object mapValue = entry.value;

      if (mapKey is! String) {
        return throw FormatException(
          '`$variableName` must be keyed by a string',
        );
      }

      if (mapValue is! String) {
        return throw FormatException(
          '`$variableName` value must be a string',
        );
      }
      checkedMap[mapKey] = mapValue;
    }
  }

  return checkedMap;
}
