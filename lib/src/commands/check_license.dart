import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/format.dart';
import 'package:license_checker/src/dependency_checker.dart';
import 'package:license_checker/src/check_license.dart';
import 'package:license_checker/src/package_checker.dart';
import 'package:license_checker/src/commands/utils.dart';

/// Command that checks license for compliance.
class CheckLicenses extends Command<int> {
  @override
  final String name = 'check-licenses';
  @override
  final String description =
      'Checks licenses of all dependencies for compliance.';

  /// Creates the check-license command and add a flag to show only "problematic"
  /// packages (non approved and permitted packages).
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
    String configPath = globalResults?['config'];

    if (filterApproved) {
      printInfo('Filtering out approved packages ...');
    }

    Config? config = loadConfig(configPath);
    if (config == null) {
      return 1;
    }

    printInfo(
      'Checking ${showDirectDepsOnly ? 'direct' : 'all'} dependencies ...',
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

    if (rows.isNotEmpty) {
      print(formatLicenseTable(rows.map((e) => e.display).toList()).render());
    }

    int exitCode = rows.any(
      (r) =>
          r.status != LicenseStatus.approved ||
          r.status != LicenseStatus.permitted,
    )
        ? 1
        : 0;
    if (rows.isEmpty || exitCode == 0) {
      printSuccess('No package licenses need approval!');
    }

    // Return error status code if any package has a license that has not been approved.
    return exitCode;
  }
}
