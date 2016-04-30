#!/bin/bash

source /datastore/run.params

# about to do some parallel work...
declare -A do_parallel

# declare function to run parallel processing
run_parallel () {
  # adapted from: http://stackoverflow.com/a/18666536/4460430
  local max_concurrent_tasks=$1
  local -A pids=()

  for key in "${!do_parallel[@]}"; do
    while [ $(jobs 2>&1 | grep -c Running) -ge "$max_concurrent_tasks" ]; do
      sleep 1 # gnu sleep allows floating point here...
    done
    echo -e "\tStarting $key"
    set -x
    ${do_parallel[$key]} &
    set +x
    pids+=(["$key"]="$!")
  done

  errors=0
  for key in "${!do_parallel[@]}"; do
    pid=${pids[$key]}
    local cur_ret=0
    if [ -z "$pid" ]; then
      echo "No Job ID known for the $key process" # should never happen
      cur_ret=1
    else
      wait $pid
      cur_ret=$?
    fi
    if [ "$cur_ret" -ne 0 ]; then
      errors=$(($errors + 1))
      echo "$key (${do_parallel[$key]}) failed."
    fi
  done

  return $errors
}

cp -r /opt/wtsi-cgp/site /datastore/site

do_parallel[progress]="progress.pl /datastore/output $NAME_MT $NAME_WT /datastore/site/data/progress.json >& ~/monitor.log"
#do_parallel[server]="cd /datastore/site && python -m SimpleHTTPServer 8000 >& ~/server.log"

run_parallel 2 do_parallel
