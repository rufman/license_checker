import 'dart:io';

import 'package:yaml/yaml.dart';

/// Represents the config parsed from a config file for the license checker.
class Config {
  /// List of permitted license.
  final List<String> permittedLicenses;

  /// List of licenses that are not allowed to be used by default.
  final List<String> rejectedLicenses;

  /// Packages by license that have been explicitly approved
  final Map<String, List<String>> approvedPackages;

  Config._({
    required this.permittedLicenses,
    required this.rejectedLicenses,
    required this.approvedPackages,
  });

  /// Parses and creates config from a file
  factory Config.fromFile(File configFile) {
    if (!configFile.existsSync()) {
      return throw FileSystemException(
        '$configFile file not found in current directory.',
      );
    }

    YamlMap config = loadYaml(configFile.readAsStringSync());

    Object? permittedLicenses = config['permittedLicenses'];
    Object? rejectedLicenses = config['rejectedLicenses'];
    Object? approvedPackages = config['approvedPackages'];
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

    List<String> stringLicenses =
        permittedLicenses.whereType<String>().toList();
    List<String> stringRejectLicenses =
        permittedLicenses.whereType<String>().toList();

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
            '`approvedPackages` must specified as a list',
          );
        }

        List<String> stringApprovedPackages =
            packages.whereType<String>().toList();

        checkedApprovedPackages[license] = stringApprovedPackages;
      }
    }

    return Config._(
      permittedLicenses: stringLicenses,
      approvedPackages: checkedApprovedPackages,
      rejectedLicenses: stringRejectLicenses,
    );
  }
}
