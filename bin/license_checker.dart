import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:path/path.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';
import 'package:license_checker/src/dependency_checker.dart';
import 'package:license_checker/src/generate_disclaimer.dart';
import 'package:license_checker/src/check_license.dart';
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
    bool showDirectDepsOnly = globalResults?['direct'];
    if (filterApproved) {
      printInfo('Filtering out approved packages ...');
    }

    Config? config = _loadConfig(globalResults);
    if (config == null) {
      return 1;
    }

    printInfo(
      'Checking ${showDirectDepsOnly ? 'direct' : 'all'} dependencies...',
    );

    List<LicenseDisplayWithPriority<Row>> rows = [];
    try {
      PackageChecker packageConfig =
          await PackageChecker.fromCurrentDirectory(config: config);
      rows = await checkAllPackageLicenses<Row>(
        packageConfig: packageConfig,
        showDirectDepsOnly: showDirectDepsOnly,
        filterApproved: filterApproved,
        licenseDisplay: formatLicenseRow,
      );
    } on FileSystemException catch (error) {
      printError(error.message);
      return 1;
    }

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
    bool showDirectDepsOnly = globalResults?['direct'];

    Config? config = _loadConfig(globalResults);
    if (config == null) {
      return 1;
    }

    printInfo(
      'Generating disclaimer for ${showDirectDepsOnly ? 'direct' : 'all'} dependencies...',
    );

    PackageChecker packageConfig =
        await PackageChecker.fromCurrentDirectory(config: config);

    DisclaimerDisplay<List<Row>, List<StringBuffer>> disclaimer =
        await generateDisclaimers<Row, StringBuffer>(
      config: config,
      packageConfig: packageConfig,
      showDirectDepsOnly: showDirectDepsOnly,
      disclaimerCLIDisplay: formatDisclaimerRow,
      disclaimerFileDisplay: formatDisclaimer,
    );

    print(
      formatDisclaimerTable(disclaimer.cli).render(),
    );

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
        StringBuffer disclaimerText = StringBuffer();
        for (StringBuffer d in disclaimer.file) {
          disclaimerText.write(d.toString());
        }
        output.writeAsStringSync(disclaimerText.toString());

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

Config? _loadConfig(ArgResults? args) {
  String configPath = args?['config'];

  printInfo('Loading config from $configPath');

  try {
    return Config.fromFile(File(configPath));
  } on FormatException catch (error) {
    printError(error.message);
    return null;
  }
}
