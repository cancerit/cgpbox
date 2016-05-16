#!/bin/bash
set -uxe

SUCCESS="/datastore/reference_files/unpack_ref.success"

if [ -e $SUCCESS ]; then
  echo "Reference area already staged"
else
  rm -rf /datastore/reference_files
  curl -sSL --retry 10 -o /datastore/ref.tar.gz ftp://ftp.sanger.ac.uk/pub/cancer/cgpbox/ref.tar.gz
  tar -C /datastore -zxf /datastore/ref.tar.gz
  touch $SUCCESS
fi
