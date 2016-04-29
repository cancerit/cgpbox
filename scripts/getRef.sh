#!/bin/bash
set -uxe
rm -rf /datastore/reference_files
curl -sSL --retry 10 -o /datastore/ref.tar.gz ftp://ftp.sanger.ac.uk/pub/cancer/cgpbox/ref.tar.gz
tar -C /datastore -zxf /datastore/ref.tar.gz
