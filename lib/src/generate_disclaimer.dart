import 'dart:io';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/dependency_checker.dart';
import 'package:license_checker/src/package_checker.dart';

/// Type defintion for the function that formats the display of the disclaimer
/// based on the license for the CLI.
typedef DisclaimerCLIDisplayFunction<D> = D Function({
  required String packageName,
  required String licenseName,
  required String copyright,
  required String sourceLocation,
});

/// Type defintion for the function that formats the display of the disclaimer
/// based on the license for a file.
typedef DisclaimerFileDisplayFunction<D> = D Function({
  required String packageName,
  required String licenseName,
  required String copyright,
  required String sourceLocation,
  required File? licenseFile,
});

/// Encapsulates a generic cli and file display.
class DisclaimerDisplay<C, F> {
  /// The display for CLI.
  final C cli;

  /// The display for a file.
  final F file;

  /// Default constructor
  DisclaimerDisplay({required this.cli, required this.file});
}

/// Generate disclaimers for all packages
Future<DisclaimerDisplay<List<C>, List<F>>> generateDisclaimers<C, F>({
  required Config config,
  required PackageChecker packageConfig,
  required bool showDirectDepsOnly,
  required DisclaimerCLIDisplayFunction<C> disclaimerCLIDisplay,
  required DisclaimerFileDisplayFunction<F> disclaimerFileDisplay,
}) async {
  DisclaimerDisplay<List<C>, List<F>> disclaimers =
      DisclaimerDisplay(cli: [], file: []);

  for (DependencyChecker package in packageConfig.packages) {
    if (showDirectDepsOnly) {
      // Ignore dependencies not defined in the packages pubspec.yaml
      if (!packageConfig.pubspec.dependencies.containsKey(package.name)) {
        continue;
      }
    }
    DisclaimerDisplay<C, F>? packageDisclaimer =
        await generatePackageDisclaimer<C, F>(
      config: config,
      package: package,
      disclaimerCLIDisplay: disclaimerCLIDisplay,
      disclaimerFileDisplay: disclaimerFileDisplay,
    );
    disclaimers.cli.add(packageDisclaimer.cli);
    disclaimers.file.add(packageDisclaimer.file);
  }

  return disclaimers;
}

/// Generate the disclaimer for a single package/
Future<DisclaimerDisplay<C, F>> generatePackageDisclaimer<C, F>({
  required Config config,
  required DependencyChecker package,
  required DisclaimerCLIDisplayFunction<C> disclaimerCLIDisplay,
  required DisclaimerFileDisplayFunction<F> disclaimerFileDisplay,
}) async {
  String copyright =
      config.copyrightNotice[package.name] ?? await package.copyright;

  return DisclaimerDisplay(
    cli: disclaimerCLIDisplay(
      packageName: package.name,
      copyright: copyright,
      licenseName: await package.licenseName,
      sourceLocation: package.sourceLocation,
    ),
    file: disclaimerFileDisplay(
      packageName: package.name,
      copyright: copyright,
      licenseName: await package.licenseName,
      sourceLocation: package.sourceLocation,
      licenseFile: package.licenseFile,
    ),
  );
}
