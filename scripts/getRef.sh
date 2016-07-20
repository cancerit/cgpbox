#!/bin/bash
set -uxe

SUCCESS="/datastore/$CGPBOX_VERSION/reference_files/unpack_ref.success"
REFTAR="ref-${CGPBOX_VERSION}.tar.gz"

if [ -e $SUCCESS ]; then
  echo "Reference area already staged"
else
  rm -rf /datastore/$CGPBOX_VERSION/ref*
  mkdir -p /datastore/$CGPBOX_VERSION
  curl -sSL --retry 10 -o /datastore/$CGPBOX_VERSION/$REFTAR ftp://ftp.sanger.ac.uk/pub/cancer/cgpbox/$REFTAR
  tar -C /datastore/$CGPBOX_VERSION -zxf /datastore/$CGPBOX_VERSION/$REFTAR
  touch $SUCCESS
  rm -f /datastore/$CGPBOX_VERSION/$REFTAR
fi
