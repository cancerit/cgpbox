#!/bin/bash

source /datastore/run.params

progress.pl /datastore/output $NAME_MT $NAME_WT /opt/site/wtsi-cgp/data/progress.json >& ~/monitor.log&

cd /opt/wtsi-cgp/site
python -m SimpleHTTPServer 8000 >& ~/server.log
