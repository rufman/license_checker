import 'dart:io';

import 'package:args/args.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';

/// Loads the config and prints some info.
Config? loadConfig(ArgResults? args) {
  String configPath = args?['config'];

  printInfo('Loading config from $configPath ...');

  try {
    return Config.fromFile(File(configPath));
  } on FormatException catch (error) {
    printError(error.message);
    return null;
  }
}
