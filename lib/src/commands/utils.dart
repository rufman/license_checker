import 'dart:io';

import 'package:colorize/colorize.dart';

import 'package:license_checker/src/config.dart';

/// Loads the config and prints some info.
Config? loadConfig(String path) {
  printInfo('Loading config from $path ...');

  try {
    return Config.fromFile(File(path));
  } on FormatException catch (error) {
    printError(error.message);
    return null;
  } on FileSystemException catch (error) {
    printError(error.message);
    return null;
  }
}

/// Prints error text to console in red.
void printError(String text) {
  color(text, front: Styles.RED);
}

/// Prints info text to console in blue.
void printInfo(String text) {
  color(text, front: Styles.BLUE);
}

/// Prints success text to console in green.
void printSuccess(String text) {
  color(text, front: Styles.GREEN);
}
