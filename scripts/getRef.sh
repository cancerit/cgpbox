#!/bin/bash
set -uxe
rm -rf /datastore/reference_files
curl -sSL --retry 10 -o /datastore/ref.tar.gz https://s3-eu-west-1.amazonaws.com/wtsi-pancancer/reference/GRCh37d5_CGP_refBundle.tar.gz
tar -C /datastore -zxf /datastore/ref.tar.gz
