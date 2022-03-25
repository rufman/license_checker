import 'dart:async';

import 'package:colorize/colorize.dart';
import 'package:test/test.dart';

import 'package:license_checker/src/commands/utils.dart';

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

    test(
      'should print green text for success',
      overridePrint(() {
        printSuccess('Dodgers');
        expect(stdout, Colorize('Dodgers').green().toString());
      }),
    );
  });

  group('Load Config', () {
    test('should properly load config', () {
      expect(
        loadConfig('test/lib/src/fixtures/valid_config.yaml')
            ?.permittedLicenses
            .length,
        equals(1),
      );
    });

    test('should return null if config can not be loaded due to invalid format',
        () {
      expect(
        loadConfig('test/lib/src/fixtures/invalid_permitted_config.yaml'),
        equals(null),
      );
    });

    test(
        'should return null if config can not be loaded because the file does not exist',
        () {
      expect(
        loadConfig('test/lib/src/fixtures/nonexistant_file.yaml'),
        equals(null),
      );
    });
  });
}
