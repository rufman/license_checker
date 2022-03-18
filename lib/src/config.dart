import 'dart:io';

import 'package:yaml/yaml.dart';

class Config {
  final List<String> permittedLicenses;
  final List<String> rejectedLicenses;
  final Map<String, List<String>> approvedPackages;

  Config({
    required this.permittedLicenses,
    required this.rejectedLicenses,
    required this.approvedPackages,
  });

  Config._({
    required this.permittedLicenses,
    required this.rejectedLicenses,
    required this.approvedPackages,
  });

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
          '`permittedLicenses` is not defined as a list');
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
              '`approvedPackages` must be keyed by a string license name');
        }
        if (packages is! List) {
          return throw FormatException(
              '`approvedPackages` must specified as a list');
        }

        List<String> stringApprovedPackages =
            packages.whereType<String>().toList();

        checkedApprovedPackages[license] = stringApprovedPackages;
      }
    }

    return Config(
      permittedLicenses: stringLicenses,
      approvedPackages: checkedApprovedPackages,
      rejectedLicenses: stringRejectLicenses,
    );
  }
}
