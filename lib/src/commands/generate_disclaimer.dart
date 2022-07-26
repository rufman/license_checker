import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';
import 'package:license_checker/src/generate_disclaimer.dart';
import 'package:license_checker/src/package_checker.dart';
import 'package:license_checker/src/commands/utils.dart';

/// Command that generates a disclaimer from all dependencies.
class GenerateDisclaimer extends Command<int> {
  @override
  final String name = 'generate-disclaimer';
  @override
  final String description =
      'Generates a disclaimer that includes all licenses.';

  /// Creates the generate-disclaimer command and adds two flags.
  /// The [file] flag allows the user to customize name of the discalimer file.
  /// The [path] flag allows the user to customize the write location for the discalimer file.
  GenerateDisclaimer() {
    argParser
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Write the disclaimers to the file without prompting.',
      )
      ..addFlag(
        'noDev',
        abbr: 'n',
        help: 'Do not include dev dependencies in the disclaimer.',
        negatable: false,
      )
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
    bool noDevDependencies = argResults?['noDev'];
    bool skipPrompts = argResults?['yes'];
    bool showDirectDepsOnly = globalResults?['direct'];
    String configPath = globalResults?['config'];

    Config? config = loadConfig(configPath);
    if (config == null) {
      return ExitCode.ioError.code;
    }

    printInfo(
      'Generating disclaimer for ${showDirectDepsOnly ? 'direct' : 'all'} dependencies ...',
    );

    PackageChecker packageConfig =
        await PackageChecker.fromCurrentDirectory(config: config);

    DisclaimerDisplay<List<Row>, List<StringBuffer>> disclaimer =
        await generateDisclaimers<Row, StringBuffer>(
      config: config,
      packageConfig: packageConfig,
      showDirectDepsOnly: showDirectDepsOnly,
      noDevDependencies: noDevDependencies,
      disclaimerCLIDisplay: formatDisclaimerRow,
      disclaimerFileDisplay: formatDisclaimer,
    );

    print(
      formatDisclaimerTable(disclaimer.cli).render(),
    );

    // Write disclaimer
    String outputFilePath = join(outputPath, disclaimerName);
    if (skipPrompts) {
      _writeFile(outputFilePath: outputFilePath, disclaimer: disclaimer);
      return ExitCode.success.code;
    }

    bool correctInfo = _promptYN('Is this information correct?');
    if (correctInfo) {
      bool writeFile = _promptYN(
        'Would you like to write the disclaimer to $outputFilePath?',
      );
      if (writeFile) {
        _writeFile(outputFilePath: outputFilePath, disclaimer: disclaimer);
      } else {
        printError('Did not write disclaimer.');
      }
    } else {
      printError('User stopped the disclaimer writing process.');
      return ExitCode.cantCreate.code;
    }

    return ExitCode.success.code;
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

  void _writeFile({
    required DisclaimerDisplay<List<Row>, List<StringBuffer>> disclaimer,
    required String outputFilePath,
  }) {
    File output = File(outputFilePath);
    printInfo('Writing disclaimer to file $outputFilePath ...');
    StringBuffer disclaimerText = StringBuffer();
    for (StringBuffer d in disclaimer.file) {
      disclaimerText.write(d.toString());
    }
    output.writeAsStringSync(disclaimerText.toString());

    printSuccess('Finished writing disclaimer.');
  }
}
