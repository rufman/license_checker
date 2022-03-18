import 'package:barbecue/barbecue.dart';
import 'package:colorize/colorize.dart';

import 'package:license_checker/src/package.dart';

/// Formats package licenses as a table.
Table formatTable(List<Row> rows) {
  return Table(
    tableStyle: TableStyle(border: true),
    header: TableSection(
      rows: [
        Row(
          cells: [
            Cell(
              Colorize('Package Name').bold().toString(),
              style:
                  CellStyle(alignment: TextAlignment.TopRight, paddingRight: 2),
            ),
            Cell(Colorize('License').bold().toString()),
          ],
          cellStyle: CellStyle(borderBottom: true),
        ),
      ],
    ),
    body: TableSection(
      cellStyle: CellStyle(paddingRight: 2),
      rows: rows,
    ),
  );
}

/// Formats the name of a license based on organization rules.
Colorize formatLicenseName(String name, LicenseStatus licenseStatus) {
  switch (licenseStatus) {
    case LicenseStatus.approved:
    case LicenseStatus.permitted:
      {
        return licenseOKFormat(name);
      }
    case LicenseStatus.rejected:
      {
        return licenseErrorFormat(name);
      }
    case LicenseStatus.unknown:
      {
        return licenseErrorFormat(name);
      }
    case LicenseStatus.noLicense:
      {
        return licenseNoInfoFormat(
          'No license file found. Add to approvedPackages under `$name` license.',
        );
      }
    case LicenseStatus.needsApproval:
      {
        return licenseNeedsApprovalFormat(name);
      }
  }
}

/// Formats a license row.
Row formatRow({
  required String packageName,
  required String licenseName,
  required LicenseStatus licenseStatus,
}) {
  return Row(
    cells: [
      Cell(packageName, style: CellStyle(alignment: TextAlignment.TopRight)),
      Cell(formatLicenseName(licenseName, licenseStatus).toString()),
    ],
  );
}

/// Formats the text in grey.
Colorize licenseNoInfoFormat(String text) {
  return Colorize(text).lightGray().bgBlue();
}

/// Formats the text in yellow.
Colorize licenseNeedsApprovalFormat(String text) {
  return Colorize(text).yellow();
}

/// Formats the text in green.
Colorize licenseOKFormat(String text) {
  return Colorize(text).green();
}

/// Formats the text in red.
Colorize licenseErrorFormat(String text) {
  return Colorize(text).red();
}

/// Prints error text to console in red.
void printError(String text) {
  color(text, front: Styles.RED);
}

/// Prints info text to console in blue.
void printInfo(String text) {
  color(text, front: Styles.BLUE);
}
