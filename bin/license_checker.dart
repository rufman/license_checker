import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';
import 'package:license_checker/src/package.dart';

File pubspecFile = File('pubspec.yaml');
File packageConfigFile = File('.dart_tool/package_config.json');

void main(List<String> arguments) async {
  exitCode = 0;

  CommandRunner<int> cmd = CommandRunner<int>(
    'license_checker',
    'A command line tool for checking licenses.',
  )..addCommand(CheckLicenses());

  int? errors = await cmd.run(arguments);
  if (errors != null) {
    exitCode = errors;
  }
}

class CheckLicenses extends Command<int> {
  @override
  final String name = 'check-licenses';
  @override
  final String description =
      'Checks licenses of all dependencies for compliance.';

  CheckLicenses() {
    argParser
      ..addFlag(
        'direct',
        abbr: 'd',
        help: 'Show license only for direct dependencies.',
        defaultsTo: false,
      )
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'The path to the YAML config specifing approved and rejected licenses and approved packages.',
        mandatory: true,
      );
  }

  @override
  Future<int> run() async {
    PackageConfig packageConfig;
    List<Row> rows = [];
    bool showDirectDepsOnly = argResults?['direct'];
    String configPath = argResults?['config'];

    printInfo('Loading config from $configPath');

    Config config = Config.fromFile(File(configPath));

    printInfo(
        'Checking ${showDirectDepsOnly ? 'direct' : 'all'} dependencies...');

    try {
      packageConfig = PackageConfig.fromFile(
        pubspecFile: pubspecFile,
        packageConfigFile: packageConfigFile,
        config: config,
      );
      for (Package package in packageConfig.packages) {
        if (showDirectDepsOnly) {
          // Ignore dependencies not defined in the packages pubspec.yaml
          if (!packageConfig.pubspec.dependencies.containsKey(package.name)) {
            continue;
          }
        }

        rows.add(
          formatRow(
            packageName: package.name,
            licenseStatus: await package.packageLicenseStatus,
            licenseName: await package.licenseName,
          ),
        );
      }
    } on FileSystemException {
      return 1;
    } on FormatException {
      return 1;
    }

    print(formatTable(rows).render());

    return 0;
  }
}
