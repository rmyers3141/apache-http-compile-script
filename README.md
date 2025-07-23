# apache-http-build-dev
## Overview
A `bash` script `apache-httpd-install-el6-el7.sh` is provided to compile and install Apache HTTP Server v2.4.x, (hereafter referred to as *Apache*) from source code.

The script currently only runs on Red Hat Enterprise Linux (RHEL) v7 and v6-based platforms but can be adapted for other, (including newer), Linux-based platforms if required.

## Prerequisites
Before running the script you will need to do the following:

- [x] Upload the Apache HTTP Server source code from https://httpd.apache.org/download.cgi, in the form of a `*.tar.gz` tarball, to the target machine.

- [x] Logon with a user account having root-level privileges (e.g. `sudo`) on the target machine.

- [x] Ensure the target machine has access to a `yum` repository that gives it access to download and install the following `.rpm` packages (or at least have these pre-installed):

`libtool.x86_64,
autoconf.noarch,
apr.x86_64,
apr-util.x86_64,
apr-devel.x86_64,
apr-util-devel.x86_64,
pcre.x86_64,
pcre-devel.x86_64,
gcc.x86_64,
make.x86_64,
perl.x86_64,
openssl.x86_64,
openssl-libs.x86_64,
openssl-devel.x86_64,
zlib.x86_64,
zlib-devel.x86_64,
expat-devel.x86_64`

## Script Execution
First upload the script to the target machine where you wish to install Apache HTTP Server and make sure it is given execution permission, e.g. 
```sh 
chmod +x ./apache-httpd-install-el6-el7.sh
```

If required, edit the following variable definitions in the script to suit your installation requirements by removing the default curly-braces values (such as `${APACHE_USER:=apache}`), replacing them with your own  values.  (*Any variable definitions not changed will use the default value given within the curly-braces*).

| Variable | Description | Default Value |
| ------ | ------ | ------ |
| APACHE_USER | The user to run the Apache HTTP Server as. | `apache` |
| APACHE_GROUP | The group to run the Apache HTTP Server as. | `apache` |
| APACHE_SHELL| The logon shell for the APACHE_USER | `/bin/false` (no shell)|
| MAKE | The full path to the `make` command. | `/usr/bin/gmake` (GNU `make` is preferred)|
| APACHE_VERSION | The version of Apache HTTP Server being installed. | `2.4.29` |
| APACHE_MEDIA | Full path to the Apache installation source tarball. | `/kits/apache/${APACHE_RELEASE}.tar.gz` |
| APR_MEDIA| Full path to the APR installation source tarball. | `/kits/apache/apr-util-1.6.1.tar.gz`|
| APRUTIL_MEDIA| Full path to the APR UTIL installation source tarball.| `/kits/apache/apr-util-1.6.1.tar.gz`|
| APACHE_ROOT| Full path of the Apache installation directory. | `/apps/apache/${APACHE_VERSION}`|
| LOG | Full path to the script's log file. | `/var/tmp/${SCRIPTNAME}.log` (change to `/dev/null` if not required)|

Then, on the target machine, switch to a user with root-level privileges (e.g. that has `sudo` access), change to the directory where the script has been uploaded to, and run the script by executing the following command:

```sh
./apache-httpd-install-el6-el7.sh
```

## Background Notes
### Motivation
Among the many advantages of compiling Apache from source is that you can more precisely control the installation options such as module selection.  

For example, one of the major advantages to compiling Apache over installing it pre-prepared by current package managers is that it lets you include the latest security features such as newer releases of *OpenSSL*.  This flexibility may be particularly important for high-profile web sites or those with strict compliance requirements.

### How the script works
The script's actions include the following.

1. Checks the user running the script has access to sudo.

2. Extracts the Apache installation media tarballs.

3. Downloads any required packages to support the compile options.

4. Checks for the presence of the required compile and build tools.

5. Compiles and installs Apache.

6. Once installed, makes some basic changes to the Apache configuration.

7. Opens the host machine's firewall ports for inbound HTTP and HTTPS traffic.

8. Create a systemd unit file to support managing the Apache HTTP Server installation as a system service and to start at boot time.

### Customising the Script
The script can be adapted to run on other Unix/Linux-based platforms.  Below is some brief guidance on how to go about doing this:

- Change the variables defined at the beginning of the script to suit your requirements.
  
- If you want to change the Apache compile options, edit the line beginning `${SUDO} ./configure` in the script appropriately.  If the changes depend on certain packages being preinstalled (which could be the case with  3rd party modules say), you may need to ensure that lines are also added to the script to install those packages first, e.g. by using the `pkg_install` function.
  
- If you want to use a different package manager, such as `apt`, modify the `pkg_install()` function to execute commands for that package manager that are appropriate.
  
- For Linux/Unix platforms that don't use `systemd` or `firewalld`, you may need to edit (or remove) the lines that use the `apache_systemd_unit_create()` and `firewalld_service_add()`, or add equivalent functions appropriate to the target platform.

### Uninstallation
The accompanying uninstall script can be used to uninstall the Apache installation and undo any changes.  To run the script, changed to the directory where it exists and execute the following command:

```sh
./uninstall-apache-httpd.sh
```

(You will need root-privileges to execute this).

This script is currently very basic and needs further development, but it will undo all the changes made by the install script.

### TO-DO List
The script has been tested as working, but is still essentially a development project, and could benefit from the following improvements:

- Compile and install Apache Portable Runtime (APR) rather than use pre-prepared packaged-based installations.
  
- Adapted to work on newer RHEL-based platforms and a wider variety of Linux varieties such as Ubuntu and Debian.

- Integrity checks on the installation media (such as PGP and checksum comparisons).

- Improvements to the accompanying uninstall script.
  
- Further security hardening.

