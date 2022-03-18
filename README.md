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
