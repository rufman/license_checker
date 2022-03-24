import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:path/path.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';
import 'package:license_checker/src/dependency_checker.dart';
import 'package:license_checker/src/package_checker.dart';

void main(List<String> arguments) async {
  exitCode = 0;

  LicenseCommandRunner cmd = LicenseCommandRunner()
    ..addCommand(CheckLicenses())
    ..addCommand(GenerateDisclaimer());

  try {
    int? errors = await cmd.run(arguments);
    if (errors != null) {
      exitCode = errors;
    }
  } on UsageException catch (e) {
    printError(e.message);
    print('');
    print(e.usage);
  }
}

class RowWithPriority {
  final Row display;
  final LicenseStatus status;
  late final int priority;

  RowWithPriority(this.display, this.status) {
    switch (status) {
      case LicenseStatus.approved:
        {
          priority = 1;
          break;
        }
      case LicenseStatus.permitted:
        {
          priority = 1;
          break;
        }
      case LicenseStatus.unknown:
        {
          priority = 2;
          break;
        }
      case LicenseStatus.rejected:
        {
          priority = 5;
          break;
        }
      case LicenseStatus.needsApproval:
        {
          priority = 4;
          break;
        }
      case LicenseStatus.noLicense:
        {
          priority = 3;
          break;
        }
    }
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
        negatable: false,
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

  CheckLicenses() {
    argParser.addFlag(
      'problematic',
      abbr: 'p',
      help:
          'Show only package with problematic license statuses (filter approved and permitted packages).',
      negatable: false,
      defaultsTo: false,
    );
  }

  @override
  Future<int> run() async {
    bool filterApproved = argResults?['problematic'];
    if (filterApproved) {
      printInfo('Filtering out approved packages ...');
    }
    List<RowWithPriority> rows = [];

    Config config = _loadConfig(globalResults);
    await _processPackage(config, globalResults,
        (DependencyChecker package) async {
      LicenseStatus status = await package.packageLicenseStatus;
      if (!filterApproved ||
          (filterApproved &&
              status != LicenseStatus.approved &&
              status != LicenseStatus.permitted)) {
        rows.add(
          RowWithPriority(
            formatLicenseRow(
              packageName: package.name,
              licenseStatus: status,
              licenseName: await package.licenseName,
            ),
            status,
          ),
        );
      }
    });

    // Sort by priority
    rows.sort((a, b) {
      if (a.priority < b.priority) {
        return -1;
      }
      if (a.priority > b.priority) {
        return 1;
      }
      return 0;
    });

    print(formatLicenseTable(rows.map((e) => e.display).toList()).render());

    // Return error status code if any package has a license that has not been approved.
    return rows.any(
      (r) =>
          r.status != LicenseStatus.approved ||
          r.status != LicenseStatus.permitted,
    )
        ? 1
        : 0;
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
    String disclaimerName = argResults?['file'];
    String outputPath = argResults?['path'];
    Config config = _loadConfig(globalResults);
    List<Row> rows = [];
    List<DependencyChecker> packageDisclaimers = [];

    await _processPackage(config, globalResults,
        (DependencyChecker package) async {
      String copyright =
          config.copyrightNotice[package.name] ?? await package.copyright;
      rows.add(
        formatDisclaimerRow(
          packageName: package.name,
          copyright: copyright,
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

typedef ProcessFunction = Future<void> Function(DependencyChecker package);

Future<int> _processPackage(
  Config config,
  ArgResults? args,
  ProcessFunction processFn,
) async {
  bool showDirectDepsOnly = args?['direct'];

  printInfo(
    'Checking ${showDirectDepsOnly ? 'direct' : 'all'} dependencies...',
  );
  try {
    PackageChecker packageConfig =
        await PackageChecker.fromCurrentDirectory(config: config);

    for (DependencyChecker package in packageConfig.packages) {
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
