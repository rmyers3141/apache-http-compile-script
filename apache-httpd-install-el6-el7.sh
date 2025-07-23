#!/bin/bash
#
################################################################################
#
# NAME:         apache-httpd-install-el6-el7.sh
# DESCRIPTION:  Installs Apache HTTP Server on RHEL6 (el6) or RHEL7 (el7) 
#               plaforms by compiling from source.
#
#               As part of the installation, Apache Portable Runtime (APR)
#               source files are also included for compiling.  (Although, the 
#               installation currently uses APR .rpms from Red Hat/Centos 
#               instead, because of an apparent bug with compiling APR 
#               source files on Centos 7.3 / RHEL 7.3).
#
#               The Apache software is installed to a directory defined by the
#               APACHE_ROOT constant, and standard firewall ports for HTTP and 
#               HTTPS opened on the Linux platform to allow incoming traffic.
#               The installed Apache is also set up as a boot-time service.
#               (Currently, the script only does this for and RHEL 7 (el7) 
#               based platforms).
#
#
# PREQUISITIES: The original source media (downloadable from the Apache
#               Software Foundation) must be available in the directory 
#               /kits/apache.   In adddition, a directory called
#               /kits/apache/install must exist as a working directory for the
#               installation.
#
#
#               The Apache software is installed to a directory defined by the
#               APACHE_ROOT variable.
#
#
################################################################################
#
#
#
# BEGIN DECLARE CONSTANTS & ENVIRONMENT VARIABLES
APACHE_USER=${APACHE_USER:=apache}
APACHE_GROUP=${APACHE_USER:=apache}
APACHE_SHELL=${APACHE_SHELL:=/bin/false}
MAKE=${MAKE:=/usr/bin/gmake}
APACHE_VERSION=${APACHE_VERSION:=2.4.29}
APACHE_RELEASE=httpd-${APACHE_VERSION}
APACHE_MEDIA=/kits/apache/${APACHE_RELEASE}.tar.gz
APR_MEDIA=/kits/apache/apr-1.6.3.tar.gz
APRUTIL_MEDIA=/kits/apache/apr-util-1.6.1.tar.gz
APACHE_ROOT=/apps/apache/${APACHE_VERSION}
IP_ADDRESS=`hostname -I | xargs`
SCRIPTNAME=`basename $0`
LOG=/var/tmp/${SCRIPTNAME}.log
#LOG=/dev/null
export PATH=$PATH:/sbin:/usr/sbin
# END DECLARE CONSTANTS & ENVIRONMENT VARIABLES
#
#
#
# BEGIN FUNCTION DEFINITIONS


# Function to handle premature script termination:
abort() {
  printf "========================================================\n" | tee -a ${LOG}
  printf "ERROR: %s\n" "$1" | tee -a ${LOG}
  printf "SCRIPT ENDED ABNORMALLY ON: %s\n" "`date`" | tee -a ${LOG}
  exit 1
}


# Check if sudo required:
sudo_check() {
  uid=`id | /bin/sed -e 's;^.*uid=;;' -e 's;\([0-9]\)(.*;\1;'`
  if [ "$uid" = "0" ] ; then
    SUDO=" "
  else
    SUDO=`which sudo 2>/dev/null`
    if [ -z "${SUDO}" ] ; then
      abort "SUDO NOT FOUND."
    fi
  fi
}


# Prepare Apache and APR source file media:
apache_media() {
  # Then extract Apache media to a holding directory under /kits/apache/install:
  ${SUDO} tar -zxf "${APACHE_MEDIA}" -C /kits/apache/install
  # Check for success:
  if [ "$?" -eq 0 ] ; then
    printf "\n=> APACHE MEDIA EXTRACTION SUCCESSFUL.\n\n" | tee -a ${LOG}
  else
     abort "APACHE MEDIA EXTRACTION FAILED, ABORTING."
  fi
}
 

# Prepare APR source file media:
apr_media() {
  if [ ! -d "/kits/apache/install/${APACHE_RELEASE}/srclib" ] ; then
    abort "THERE APPEARS TO BE A PROBLEM WITH THE APACHE SOURCE FILES, ABORTING."
  else
    # First extract APR media:
    ${SUDO} mkdir -p /kits/apache/install/${APACHE_RELEASE}/srclib/apr &&
    ${SUDO} tar --strip-components=1 -zxf "${APR_MEDIA}" -C "/kits/apache/install/${APACHE_RELEASE}/srclib/apr"
    if [ "$?" -eq 0 ] ; then
      printf "\n=> APR MEDIA EXTRACTED SUCCESSFULLY.\n\n" | tee -a ${LOG}
    else
      abort "A PROBLEM OCCURRED EXTRACTING THE APR MEDIA, ABORTING."
    fi
    # Then extract APR-UTIL media:
    ${SUDO} mkdir -p /kits/apache/install/${APACHE_RELEASE}/srclib/apr-util &&
    ${SUDO} tar --strip-components=1 -zxf "${APRUTIL_MEDIA}" -C "/kits/apache/install/${APACHE_RELEASE}/srclib/apr-util"
    if [ "$?" -eq 0 ] ; then
      printf "\n=> APR-UTIL MEDIA EXTRACTED SUCCESSFULLY.\n\n" | tee -a ${LOG}
    else
      abort "A PROBLEM OCCURRED EXTRACTING THE APR-UTIL MEDIA, ABORTING."
    fi
  fi
}


# Function to install .rpms specified by $1 using yum
pkg_install() {
  if [ "$1" == "" ] ; then
    abort "PACKAGE NAME NOT SPECIFIED, PLEASE SPECIFY PACKAGE NAME AS FIRST ARGUMENT."
  else
    # Run yum in quiet mode:
    ${SUDO} yum --assumeyes --quiet install "$1"
    if [ "$?" -eq 0 ] ; then
      printf "PACKAGE INSTALLED, UPDATED, OR ALREADY UP-TO-DATE: $1 \n"  | tee -a ${LOG}
    else
      abort "PACKAGE FAILED INSTALLATION, UPDATING, OR CHECKING: $1"
    fi
  fi
}

 
# Verify gcc is present:
gcc_check() {
  if command -v gcc >/dev/null 2>&1 ; then
    printf "=> gcc FOUND!\n\n" | tee -a ${LOG}
  else
    abort "gcc NOT FOUND, ABORTING!" 
  fi
}


# Check preferred GNU make is present:
make_check() {
  if [ ! -f "${MAKE}" ] ; then
    abort "REQUIRED make COMMAND ${MAKE} NOT FOUND, ABORTING!"
  else
    printf "=> REQUIRED make COMMAND ${MAKE} FOUND.\n\n" | tee -a ${LOG}
  fi
}  
  

 Ensure Apache group exists:
group_check() {
  if ${SUDO} getent group "${APACHE_GROUP}" > /dev/null 2>&1 ; then
    printf "=> GROUP ${APACHE_GROUP} ALREADY EXISTS.\n\n"  | tee -a ${LOG}
  else
    printf "GROUP ${APACHE_GROUP} DOES NOT EXIST YET, ADDING GROUP..."  | tee -a ${LOG}
    ${SUDO} groupadd "${APACHE_GROUP}" ||
    abort "PROBLEM CREATING ${APACHE_GROUP} GROUP, ABORTING."
    printf "DONE.\n\n"  | tee -a ${LOG}
  fi
}


# Ensure Apache user exists:
user_check() {
  if ${SUDO} getent passwd "${APACHE_USER}" > /dev/null 2>&1 ; then
    printf "=> USER ${APACHE_USER} ALREADY EXISTS.\n\n" | tee -a ${LOG}
  else
    printf "USER ${APACHE_USER} DOES NOT EXIST YET, ADDING USER..."  | tee -a ${LOG}
    ${SUDO} useradd -g ${APACHE_GROUP} -s ${APACHE_SHELL} ${APACHE_USER} ||
    abort "PROBLEM CREATING ${APACHE_USER} USER, ABORTING."
    # Once created, lock the account:
    passwd -l ${APACHE_USER}
    printf "DONE.\n\n"  | tee -a ${LOG}
  fi
}


# Add a service to firewalld's default zone and make it permanent.
firewalld_service_add() {
  if [ "$1" == "" ] ; then
    abort "SERVICE NAME NOT SPECIFIED, PLEASE SPECIFY SERVICE NAME AS FIRST ARGUMENT."
  else
    ${SUDO} firewall-cmd --add-service "$1" > /dev/null 2>&1 &&
    ${SUDO} firewall-cmd --permanent --add-service "$1" > /dev/null 2>&1
    if [ "$?" -eq 0 ] ; then
      printf "\n\n=> $1 SERVICE OPENED ON FIREWALL.\n\n" | tee -a ${LOG}
    else
      abort "A PROBLEM OCCURRED OPENING THE $1 SERVICE ON THE FIREWALL."
    fi
  fi
}  


# Create Apache systemd unit file for RHEL7-based platforms:
# The unit file created is called "apache.service".
apache_systemd_unit_create() {
#
${SUDO} touch /etc/systemd/system/apache.service
${SUDO} chmod 664 /etc/systemd/system/apache.service
#
${SUDO} cat > /etc/systemd/system/apache.service << EOF
[Unit]
Description=Apache HTTP Server (compiled)
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=${APACHE_ROOT}/bin/apachectl start
ExecStop=${APACHE_ROOT}/bin/apachectl stop
Restart=${APACHE_ROOT}/bin/apachectl restart
ExecReload=${APACHE_ROOT}/bin/apachectl restart
PIDFile=${APACHE_ROOT}/logs/httpd.pid

[Install]
WantedBy=default.target
EOF
#
#
${SUDO} systemctl daemon-reload
${SUDO} systemctl enable apache.service
if [ "$?" -eq 0 ] ; then
  printf "\n\n=> APACHE SYSTEMD SERVICE CREATED SUCCESSFULLY.\n\n" | tee -a ${LOG}
else
  abort "A PROBLEM OCCURRED APACHE SYSTEMD SERVICE."
fi

}
  

# END FUNCTION DEFINITIONS

########################################################################
# MAIN
########################################################################
printf "STARTING SCRIPT ON: %s\n" "`date`" | tee ${LOG}
printf "========================================================\n\n" | tee -a ${LOG}

# Find out if we need sudo:
sudo_check


# Install prerequisite .rpms:
printf "INSTALLING/UPDATING PREREQUISITE .RPMs: %s\n\n" "`date`" | tee ${LOG}
pkg_install libtool.x86_64
pkg_install autoconf.noarch

# Install APR .rpms as there appears to a be a bug with compiled APR - Feb 2018.
pkg_install apr.x86_64
pkg_install apr-util.x86_64
pkg_install apr-devel.x86_64
pkg_install apr-util-devel.x86_64

pkg_install pcre.x86_64
pkg_install pcre-devel.x86_64
pkg_install gcc.x86_64
pkg_install make.x86_64
pkg_install perl.x86_64

pkg_install openssl.x86_64
pkg_install openssl-libs.x86_64
pkg_install openssl-devel.x86_64

pkg_install zlib.x86_64
pkg_install zlib-devel.x86_64

# Added, as there appears to be a bug with compiling APR - Feb 2018.
pkg_install expat-devel.x86_64

printf "INSTALLED/UPDATED PREREQUISITE .RPMs! \n\n%s\n\n" "`date`" | tee -a ${LOG}


# Further prerequisite checks:
gcc_check
make_check

 
# Prepare source media:
apache_media
# apr_media


# Ensure APACHE_ROOT exists:
if [ ! -d "${APACHE_ROOT}" ] ; then
  ${SUDO} mkdir -p "${APACHE_ROOT}"   
fi


# Run configure with desired options:
cd "/kits/apache/install/${APACHE_RELEASE}"
${SUDO} ./configure --prefix=${APACHE_ROOT} \
                      --with-mpm=worker \
                      --enable-mods-shared=reallyall | tee -a ${LOG}
if [ "$?" -eq 0 ] ; then
  printf "\n\n => configure SCRIPT RUN SUCCESSFULLY.\n\n" | tee -a ${LOG}
else
  abort "PROBLEM OCCURRED RUNNING configure SCRIPT, ABORTING."
fi


# Run make:
${SUDO} ${MAKE} | tee -a ${LOG}
if [ "$?" -eq 0 ] ; then
  printf "\n\n=> make RAN SUCCESSFULLY.\n\n" | tee -a ${LOG}
else
  abort "PROBLEM OCCURRED RUNNING make, ABORTING."
fi


# Run make install:
${SUDO} ${MAKE} install | tee -a ${LOG}
if [ "$?" -eq 0 ] ; then
  printf "\n\n=> make install RAN SUCCESSFULLY.\n\n" | tee -a ${LOG}
else
  abort "PROBLEM OCCURRED RUNNING make install, ABORTING."
fi


# Change user/group of Apache installation:
group_check
user_check
${SUDO} chown -R ${APACHE_USER}:${APACHE_GROUP} "${APACHE_ROOT}"
${SUDO} cp -p "${APACHE_ROOT}/conf/httpd.conf" "${APACHE_ROOT}/conf/httpd.conf_orig"
${SUDO} sed -i -e "s/^User daemon/User ${APACHE_USER}/" \
               -e "s/^Group daemon/Group ${APACHE_GROUP}/" \
               "${APACHE_ROOT}/conf/httpd.conf"
if [ "$?" -eq 0 ] ; then
   printf "\n\n=> USER/GROUP CHANGES MADE SUCCESSFULLY.\n\n"  | tee -a ${LOG}
else
  abort "USER/GROUP CHANGES FAILED, ABORTING." 
fi


# Edit Listen directive in httpd.conf:
${SUDO} sed -i -e "s/^Listen 80/Listen ${IP_ADDRESS}:80/" \
                  "${APACHE_ROOT}/conf/httpd.conf"
if [ "$?" -eq 0 ] ; then
   printf "\n\n=> LISTEN IP ADDRESS UPDATED.\n\n" | tee -a ${LOG}
else
  abort "FAILED TO UPDATE LISTEN DIRECTIVE IN httpd.conf, ABORTING."
fi


# Create boot-time start-up services & firewall rules for Apache on RHEL7 and RHEL6:
case `uname -r` in
  *el7*x86_64*)
    apache_systemd_unit_create 
    firewalld_service_add http
    firewalld_service_add https
    ;;
  *el6*x86_64*)
    echo "TO-DO!"
    ;;
  *)
    abort "O.S. NOT RECOGNISED!"
    ;;
esac



printf "\n========================================================\n" | tee -a ${LOG}
printf "SCRIPT ENDED ON: %s\n" "`date`" | tee -a ${LOG}

exit 0

##########################################################################
# END OF MAIN
##########################################################################

