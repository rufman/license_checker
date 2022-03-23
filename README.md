[![codecov](https://codecov.io/gh/rufman/license_checker/branch/trunk/graph/badge.svg?token=V20VQE4GPK)](https://codecov.io/gh/rufman/license_checker) [![Dart](https://github.com/rufman/license_checker/actions/workflows/dart.yml/badge.svg)](https://github.com/rufman/license_checker/actions/workflows/dart.yml) [![Pub](https://img.shields.io/pub/v/license_checker.svg)](https://pub.dev/packages/license_checker)

Displays the license of dependencies. Permitted, rejected and approved packages are configurable
through a YAML config file,

# Install

`dart pub global activate license_checker`

# Getting Started

Create a YAML config file. Example:

```yaml
permittedLicenses:
  - MIT
  - BSD-3-Clause

approvedPackages:
  Apache-2.0:
    - barbecue

rejectedLicenses:
  - GPL
```

This file can be referenced when calling `lic_ck check-licenses` with the `--config` option.

`lic_ck` or `lic_ck -h` will display help
