#!/bin/bash

set -eux

sudo apt-get -yq update
sudo apt-get -yq install apt-transport-https
sudo apt-get -yq install autoconf
sudo apt-get -yq install bsdtar
sudo apt-get -yq install build-essential
sudo apt-get -yq install ca-certificates
sudo apt-get -yq install curl
sudo apt-get -yq install gfortran
sudo apt-get -yq install libboost-dev
sudo apt-get -yq install libboost-iostreams-dev
sudo apt-get -yq install libcairo2-dev
sudo apt-get -yq install libcurl4-openssl-dev
sudo apt-get -yq install libexpat1-dev
sudo apt-get -yq install libglib2.0-dev
sudo apt-get -yq install libgnutls-dev
sudo apt-get -yq install libgoogle-perftools-dev
sudo apt-get -yq install libncurses5-dev
sudo apt-get -yq install libpstreams-dev
sudo apt-get -yq install libreadline6-dev
sudo apt-get -yq install libssl-dev
sudo apt-get -yq install nettle-dev
sudo apt-get -yq install nfs-common
sudo apt-get -yq install python-software-properties
sudo apt-get -yq install r-base r-base-dev
sudo apt-get -yq install s3cmd
sudo apt-get -yq install software-properties-common
sudo apt-get -yq install unzip
sudo apt-get -yq install zlib1g-dev
sudo apt-get -yq install libpam-tmpdir
# install all perl libs, identify by grep of cgp_box_stack build "grep 'Successfully installed' build_stack.log"
# much faster, items needing later versions will still upgrade
# still install those that get an upgrade though as dependancies will be resolved
sudo apt-get -yq install libwww-perl
sudo apt-get -yq install libextutils-cbuilder-perl # gets upgraded
sudo apt-get -yq install libmodule-build-perl # gets upgraded
sudo apt-get -yq install libextutils-helpers-perl
sudo apt-get -yq install libextutils-config-perl
sudo apt-get -yq install libextutils-installpaths-perl
sudo apt-get -yq install libmodule-build-tiny-perl
sudo apt-get -yq install libfile-sharedir-install-perl # gets upgraded
sudo apt-get -yq install libclass-inspector-perl
sudo apt-get -yq install libfile-sharedir-perl
sudo apt-get -yq install libsub-exporter-progressive-perl
sudo apt-get -yq install libconst-fast-perl
sudo apt-get -yq install libfile-which-perl # gets upgraded
sudo apt-get -yq install libio-string-perl
sudo apt-get -yq install libdata-stag-perl
sudo apt-get -yq install libtest-deep-perl
sudo apt-get -yq install libtext-diff-perl
sudo apt-get -yq install libcapture-tiny-perl # possible may need more recent version, should upgrade via makefiles in CGP code if needed
sudo apt-get -yq install libtest-differences-perl
sudo apt-get -yq install libtest-simple-perl # gets upgraded
sudo apt-get -yq install libdevel-stacktrace-perl
sudo apt-get -yq install libclass-data-inheritable-perl
sudo apt-get -yq install libexception-class-perl
sudo apt-get -yq install libsub-uplevel-perl
sudo apt-get -yq install libtest-exception-perl
sudo apt-get -yq install libtest-warn-perl
sudo apt-get -yq install libtest-most-perl
sudo apt-get -yq install libbioperl-perl
sudo apt-get -yq install libtry-tiny-perl
sudo apt-get -yq install libappconfig-perl
sudo apt-get -yq install libtest-leaktrace-perl
sudo apt-get -yq install libtemplate-toolkit-perl # gets upgraded
sudo apt-get -yq install libio-stringy-perl
sudo apt-get -yq install libconfig-inifiles-perl
sudo apt-get -yq install libdata-uuid-perl
sudo apt-get -yq install liblog-message-perl
sudo apt-get -yq install liblog-message-simple-perl
sudo apt-get -yq install libterm-ui-perl
sudo apt-get -yq install libversion-perl # gets upgraded
sudo apt-get -yq install libxml-namespacesupport-perl
sudo apt-get -yq install libxml-sax-base-perl
sudo apt-get -yq install libxml-sax-perl
sudo apt-get -yq install libxml-sax-expat-perl
sudo apt-get -yq install libxml-simple-perl
sudo apt-get -yq install libjson-perl
sudo apt-get -yq install libdevel-cover-perl
sudo apt-get -yq install libtest-fatal-perl
sudo apt-get -yq install libdevel-symdump-perl
sudo apt-get -yq install libpod-coverage-perl
sudo apt-get -yq install libproc-pid-file-perl
sudo apt-get -yq install libcanary-stability-2012-perl
sudo apt-get -yq install libcommon-sense-perl
sudo apt-get -yq install libtypes-serialiser-perl
sudo apt-get -yq install libjson-xs-perl
sudo apt-get -yq install libproc-processtable-perl
sudo apt-get -yq install libfile-remove-perl
sudo apt-get -yq install libtest-object-perl
sudo apt-get -yq install libexporter-tiny-perl
sudo apt-get -yq install libxsloader-perl # gets upgraded
sudo apt-get -yq install liblist-moreutils-perl
sudo apt-get -yq install libtask-weaken-perl
sudo apt-get -yq install libtest-nowarnings-perl
sudo apt-get -yq install libparams-util-perl
sudo apt-get -yq install libhook-lexwrap-perl
sudo apt-get -yq install libtest-subcalls-perl
sudo apt-get -yq install libclone-perl
sudo apt-get -yq install libppi-perl
sudo apt-get -yq install libcss-tiny-perl
sudo apt-get -yq install libppi-html-perl
sudo apt-get -yq install libmodule-runtime-perl
sudo apt-get -yq install libdist-checkconflicts-perl
sudo apt-get -yq install libsub-identify-perl
sudo apt-get -yq install libpackage-stash-xs-perl
sudo apt-get -yq install libmodule-implementation-perl
sudo apt-get -yq install libpackage-stash-perl
sudo apt-get -yq install libvariable-magic-perl
sudo apt-get -yq install libb-hooks-endofscope-perl
sudo apt-get -yq install libnamespace-clean-perl
sudo apt-get -yq install libnamespace-autoclean-perl
sudo apt-get -yq install libmro-compat-perl
sudo apt-get -yq install libeval-closure-perl
sudo apt-get -yq install librole-tiny-perl
sudo apt-get -yq install libspecio-perl
sudo apt-get -yq install libscalar-list-utils-perl # gets upgraded
sudo apt-get -yq install libparams-validationcompiler-perl
sudo apt-get -yq install libdatetime-locale-perl
sudo apt-get -yq install libclass-singleton-perl
sudo apt-get -yq install libdatetime-timezone-perl
sudo apt-get -yq install libdatetime-perl
sudo apt-get -yq install libautodie-perl # gets upgraded
sudo apt-get -yq install libsort-key-perl
sudo apt-get -yq install liblog-log4perl-perl
sudo apt-get -yq install libfile-type-perl
sudo apt-get -yq install libnumber-format-perl
sudo apt-get -yq install libipc-run-perl
sudo apt-get -yq install libstatistics-basic-perl
sudo apt-get -yq install libmath-combinatorics-perl
sudo apt-get -yq install libparse-yapp-perl
sudo apt-get -yq install libxml-writer-perl
sudo apt-get -yq install libgraph-readwrite-perl
sudo apt-get clean
