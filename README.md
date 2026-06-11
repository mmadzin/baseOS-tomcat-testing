# BaseOS Tomcat Testing

This repository contains scripts for testing Tomcat on baseOS.

## Included Scripts

The project includes the following shell scripts:
* `unit-tests.sh`: Runs the Tomcat unit tests. Usage: `./unit-test.sh <tomcat-src-rpm-link>`
   * Check the results: `grep -P '(Failures|Errors): (?!0)' tomcat/apache-tomcat-*-src/test.log`
* `compare-rpms.sh`: Compares new source code RPM with previous version. Usage: `./compare-rpms.sh <new_tomcat-src-rpm-link> <previous_tomcat-src-rpm-link>`
* `default-test.sh`: Installs tomcat and executes the default test. If you want to install tomcat9 instead of tomcat package. Use option "tomcat9". Usage: `./default-test.sh [tomcat9]`
