import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
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
    String configPath = globalResults?['config'];

    Config? config = loadConfig(configPath);
    if (config == null) {
      return 1;
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

        printSuccess('Finished writing disclaimer.');
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
