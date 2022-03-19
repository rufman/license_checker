import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:path/path.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';
import 'package:license_checker/src/package.dart';
import 'package:license_checker/src/package_config.dart';

File pubspecFile = File('pubspec.yaml');
File packageConfigFile = File('.dart_tool/package_config.json');

void main(List<String> arguments) async {
  exitCode = 0;

  LicenseCommandRunner cmd = LicenseCommandRunner()
    ..addCommand(CheckLicenses())
    ..addCommand(GenerateDisclaimer());

  int? errors = await cmd.run(arguments);
  if (errors != null) {
    exitCode = errors;
  }
}

class LicenseCommandRunner extends CommandRunner<int> {
  LicenseCommandRunner()
      : super(
          'license_checker',
          'A command line tool for checking licenses.',
        ) {
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
}

class CheckLicenses extends Command<int> {
  @override
  final String name = 'check-licenses';
  @override
  final String description =
      'Checks licenses of all dependencies for compliance.';

  @override
  Future<int> run() async {
    List<Row> rows = [];
    bool showDirectDepsOnly = globalResults?['direct'];

    Config config = _loadConfig(globalResults);

    printInfo(
      'Checking ${showDirectDepsOnly ? 'direct' : 'all'} dependencies...',
    );

    await _processPackage(config, globalResults, (Package package) async {
      rows.add(
        formatLicenseRow(
          packageName: package.name,
          licenseStatus: await package.packageLicenseStatus,
          licenseName: await package.licenseName,
        ),
      );
    });

    print(formatLicenseTable(rows).render());

    return 0;
  }
}

class GenerateDisclaimer extends Command<int> {
  @override
  final String name = 'generate-disclaimer';
  @override
  final String description =
      'Generates a disclaimer that includes all licenses.';

  GenerateDisclaimer() {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'The name of the disclaimer file.',
        defaultsTo: 'DISCLAIMER',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path at which to write the disclaimer.',
        defaultsTo: Directory.current.path,
      );
  }

  @override
  Future<int> run() async {
    bool showDirectDepsOnly = globalResults?['direct'];
    String disclaimerName = argResults?['file'];
    String outputPath = argResults?['path'];
    Config config = _loadConfig(globalResults);
    List<Row> rows = [];
    List<Package> packageDisclaimers = [];

    await _processPackage(config, globalResults, (Package package) async {
      rows.add(
        formatDisclaimerRow(
          packageName: package.name,
          copyright: await package.copyright,
          licenseName: await package.licenseName,
          sourceLocation: package.sourceLocation,
        ),
      );
      packageDisclaimers.add(package);
    });

    print(formatDisclaimerTable(rows).render());

    // Write disclaimer
    bool correctInfo = _promptYN('Is this information correct?');
    if (correctInfo) {
      String outputFilePath = join(outputPath, disclaimerName);
      bool writeFile = _promptYN(
        'Would you like to write the disclaimer to $outputFilePath?',
      );
      if (writeFile) {
        File output = File(outputFilePath);
        printInfo('Writing disclaimer to file $outputFilePath ...');
        output
            .writeAsStringSync(await formatDisclaimerFile(packageDisclaimers));
        printInfo('Finished writing disclaimer.');
      } else {
        printError('Did not write disclaimer.');
      }
    } else {
      printError('User stopped the disclaimer writing process.');
      return 1;
    }

    return 0;
  }

  bool _promptYN(String prompt) {
    stdout.write('$prompt (y/n): ');
    String? input = stdin.readLineSync();
    if (input == 'y') {
      return true;
    }
    if (input == 'n') {
      return false;
    }
    // not y or n, so repromted
    stdout.writeln('you entered $input, please enter y or n.');
    return _promptYN(prompt);
  }
}

Config _loadConfig(ArgResults? args) {
  String configPath = args?['config'];

  printInfo('Loading config from $configPath');

  return Config.fromFile(File(configPath));
}

typedef ProcessFunction = Future<void> Function(Package package);

Future<int> _processPackage(
  Config config,
  ArgResults? args,
  ProcessFunction processFn,
) async {
  bool showDirectDepsOnly = args?['direct'];
  try {
    PackageConfig packageConfig = PackageConfig.fromFile(
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
      await processFn(package);
    }
  } on FileSystemException catch (error) {
    printError(error.message);
    return 1;
  } on FormatException catch (error) {
    printError(error.message);
    return 1;
  }
  return 0;
}
