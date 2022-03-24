import 'dart:async';
import 'dart:io';

import 'package:barbecue/barbecue.dart';
import 'package:colorize/colorize.dart';
import 'package:test/test.dart';

import 'package:license_checker/src/dependency_checker.dart';
import 'package:license_checker/src/format.dart';

class _ColorizeTest {
  final Colorize color;
  final Colorize formatFunction;
  final String testDescription;

  _ColorizeTest({
    required this.color,
    required this.formatFunction,
    required this.testDescription,
  });
}

void main() {
  group('Console print functions', () {
    String stdout = '';

    void Function() overridePrint(void Function() testFn) {
      return () {
        ZoneSpecification spec = ZoneSpecification(
          print: (_, __, ___, String msg) {
            // Add to log instead of printing to stdout
            stdout = msg;
          },
        );
        return Zone.current.fork(specification: spec).run<void>(testFn);
      };
    }

    setUpAll(() => stdout = '');
    test(
      'should print blue text for info',
      overridePrint(() {
        printInfo('LA');
        expect(stdout, Colorize('LA').blue().toString());
      }),
    );

    test(
      'should print red text for errors',
      overridePrint(() {
        printError('Anaheim');
        expect(stdout, Colorize('Anaheim').red().toString());
      }),
    );
  });

  group('Colorize formatting functions', () {
    const text = 'opening day';
    List<_ColorizeTest> colorizeTests = [
      _ColorizeTest(
        color: Colorize(text).lightGray().bgBlue(),
        formatFunction: licenseNoInfoFormat(text),
        testDescription:
            'should color no license info as gray with blue background',
      ),
      _ColorizeTest(
        color: Colorize(text).yellow(),
        formatFunction: licenseNeedsApprovalFormat(text),
        testDescription: 'should color needs approval in yellow',
      ),
      _ColorizeTest(
        color: Colorize(text).green(),
        formatFunction: licenseOKFormat(text),
        testDescription: 'should color approved in green',
      ),
      _ColorizeTest(
        color: Colorize(text).red(),
        formatFunction: licenseErrorFormat(text),
        testDescription: 'should color rejected in red',
      ),
      _ColorizeTest(
        color: Colorize(unknownSource).red(),
        formatFunction: formatSource(unknownSource),
        testDescription: 'should color unknown source in red',
      ),
      _ColorizeTest(
        color: Colorize(text).default_slyle(),
        formatFunction: formatSource(text),
        testDescription: 'should color known source in default style',
      ),
      _ColorizeTest(
        color: Colorize(unknownCopyright).red(),
        formatFunction: formatCopyright(unknownCopyright),
        testDescription: 'should color unknown copyright in red',
      ),
      _ColorizeTest(
        color: Colorize(text).default_slyle(),
        formatFunction: formatCopyright(text),
        testDescription: 'should color known copyright in default style',
      ),
      _ColorizeTest(
        color: Colorize(text).green(),
        formatFunction: formatLicenseName(text, LicenseStatus.permitted),
        testDescription: 'should color permitted license name in green',
      ),
      _ColorizeTest(
        color: Colorize(text).green(),
        formatFunction: formatLicenseName(text, LicenseStatus.approved),
        testDescription: 'should color approved license name in green',
      ),
      _ColorizeTest(
        color: Colorize(text).red(),
        formatFunction: formatLicenseName(text, LicenseStatus.rejected),
        testDescription: 'should color rejected license name in red',
      ),
      _ColorizeTest(
        color: Colorize(text).red(),
        formatFunction: formatLicenseName(text, LicenseStatus.unknown),
        testDescription: 'should color unknown license name in red',
      ),
      _ColorizeTest(
        color: Colorize(
          'No license file found. Add to approvedPackages under `$text` license.',
        ).lightGray().bgBlue(),
        formatFunction: formatLicenseName(text, LicenseStatus.noLicense),
        testDescription:
            'should color no license in gray with blue background with proper text',
      ),
      _ColorizeTest(
        color: Colorize(text).yellow(),
        formatFunction: formatLicenseName(text, LicenseStatus.needsApproval),
        testDescription:
            'should color license name that needs approval in yellow',
      ),
    ];

    for (_ColorizeTest t in colorizeTests) {
      test(t.testDescription, () {
        expect(t.formatFunction.toString(), t.color.toString());
      });
    }
  });

  group('License table formatting', () {
    Row r = formatLicenseRow(
      licenseName: 'baseball',
      licenseStatus: LicenseStatus.unknown,
      packageName: 'mlb',
    );
    test('should properly format a row', () {
      expect(r.cells.length, equals(2));
      expect(r.cells.first.content, equals('mlb'));
      expect(r.cells.last.content, contains('baseball'));
    });

    test('should properly format the table', () {
      Table t = formatLicenseTable([r]);

      expect(t.body.rows.length, equals(1));
      expect(t.body.rows[0].cells.length, equals(2));
      expect(t.header?.rows.length, equals(1));
      expect(t.header?.rows.first.cells.length, equals(2));
      expect(t.header?.rows.first.cells[0].content, contains('Package Name'));
      expect(t.header?.rows.first.cells[1].content, contains('License'));
    });
  });

  group('Disclaimer table formatting', () {
    Row r = formatDisclaimerRow(
      licenseName: 'baseball',
      copyright: 'unknown',
      packageName: 'mlb',
      sourceLocation: 'mlb.com',
    );

    test('should properly format a row', () {
      expect(r.cells.length, equals(4));
      expect(r.cells[0].content, equals('mlb'));
      expect(r.cells[1].content, equals('baseball'));
      expect(r.cells[2].content, contains('unknown'));
      expect(r.cells[3].content, contains('mlb.com'));
    });

    test('should properly format the table', () {
      Table t = formatDisclaimerTable([r]);

      expect(t.body.rows.length, equals(1));
      expect(t.body.rows[0].cells.length, equals(4));
      expect(t.header?.rows.length, equals(1));
      expect(t.header?.rows.first.cells.length, equals(4));
      expect(t.header?.rows.first.cells[0].content, contains('Package Name'));
      expect(t.header?.rows.first.cells[1].content, contains('License'));
      expect(
        t.header?.rows.first.cells[2].content,
        contains('Detected Copyright'),
      );
      expect(
        t.header?.rows.first.cells[3].content,
        contains('Source Download Location'),
      );
    });

    test('should properly format the file with license and copyright',
        () async {
      StringBuffer strBuff = formatDisclaimer(
        packageName: 'dodgers',
        licenseName: 'Apache-2.0',
        copyright: '2022 Los Angeles',
        sourceLocation: 'https://chavez.ravine',
        licenseFile: File(
          Directory.current.absolute.path +
              '/test/lib/src/fixtures/dodgers/LICENSE',
        ),
      );
      String s = strBuff.toString();

      expect(
        s,
        contains('The following software may be included in this product'),
      );
      expect(
        s,
        contains('A copy of the source code may be downloaded from'),
      );
      expect(
        s,
        contains(
          'This software contains the following license and notice below',
        ),
      );
      expect(s, contains('Copyright (c)'));
    });

    test('should properly format the file with no license', () async {
      StringBuffer strBuff = formatDisclaimer(
        packageName: 'angeles',
        licenseName: unknownLicense,
        copyright: unknownCopyright,
        sourceLocation: 'https://www.mlb.com/angels',
        licenseFile: null,
      );
      String s = strBuff.toString();

      expect(
        s,
        contains('The following software may be included in this product'),
      );
      expect(s, contains('A copy of the source code may be downloaded from'));
      expect(
        s,
        isNot(
          contains(
            'This software contains the following license and notice below',
          ),
        ),
      );
      expect(s, isNot(contains('Copyright (c)')));
    });
  });
}
