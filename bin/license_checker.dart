import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import 'package:license_checker/command_runner.dart';
import 'package:license_checker/src/commands/check_license.dart';
import 'package:license_checker/src/commands/generate_disclaimer.dart';
import 'package:license_checker/src/commands/utils.dart';

void main(List<String> arguments) async {
  exitCode = ExitCode.success.code;

  LicenseCommandRunner cmd = LicenseCommandRunner()
    ..addCommand(CheckLicenses())
    ..addCommand(GenerateDisclaimer());

  try {
    int? errors = await cmd.run(arguments);
    if (errors != null && errors != 0) {
      exitCode = ExitCode.software.code;
    }
  } on UsageException catch (e) {
    printError(e.message);
    print('');
    print(e.usage);
    exitCode = ExitCode.usage.code;
  }
}
