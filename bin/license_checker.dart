import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:license_checker/command_runner.dart';
import 'package:license_checker/src/commands/check_license.dart';
import 'package:license_checker/src/commands/generate_disclaimer.dart';
import 'package:license_checker/src/format.dart';

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
