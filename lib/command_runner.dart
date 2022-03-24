import 'package:args/command_runner.dart';

/// Overarching command runner for license checking related commands
class LicenseCommandRunner extends CommandRunner<int> {
  /// Creates the command runner with two global flags.
  /// The [config] flag is mandetory and specifies where the configuration for
  ///  checking licenses is. This is where accepted, rejected licenses and approved
  /// packages, as well as overridden copyright notices are defined.
  /// The [direct] flag, if set will only check direct dependencies (ones defined
  /// in the pubspec.yaml).
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
