#!/bin/bash

TIME_FORMAT='command:%C\nreal:%e\nuser:%U\nsys:%S\ntext:%Xk\ndata:%Dk\nmax:%Mk\n';

set -e

echo -e "\nStart workflow: `date`\n"

if [ -z ${CPU+x} ]; then
  CPU=`grep -c ^processor /proc/cpuinfo`
fi

declare -a PRE_EXEC
declare -a POST_EXEC

echo "Loading user options..."
source $HOME/map.params

set -u
echo -e "\tSAMPLE_NAME : $SAMPLE_NAME"
echo -e "\tINPUT_DIR : $INPUT_DIR"
echo -e "\tREF_BASE : $REF_BASE"
echo -e "\tCRAM : $CRAM"
if [ -z ${SCRAMBLE+x} ]; then
  echo -e "\tSCRAMBLE : <NOTSET>"
else
  echo -e "\tSCRAMBLE : $SCRAMBLE"
fi
set +u

if [ ${#PRE_EXEC[@]} -eq 0 ]; then
  PRE_EXEC='echo No PRE_EXEC defined'
fi

if [ ${#POST_EXEC[@]} -eq 0 ]; then
  POST_EXEC='echo No POST_EXEC defined'
fi

set -u

# run any pre-exec step before attempting to access BAMs
# logically the pre-exec could be pulling them
echo -e "\nRun PRE_EXEC: `date`"

for i in "${PRE_EXEC[@]}"; do
  set -x
  $i
  { set +x; } 2> /dev/null
done

ADD_ARGS=''
if [ $CRAM -gt 0 ]; then
  ADD_ARGS = "$ADD_ARGS -c"
  if [ ! -z ${SCRAMBLE+x} ]; then
    ADD_ARGS = "$ADD_ARGS -sc '$SCRAMBLE'";
  fi
fi


# use a different malloc library when cores for mapping are over 8
if [ $CPU -gt 7 ]; then
  ADD_ARGS = "$ADD_ARGS -l /usr/lib/libtcmalloc_minimal.so"
fi

mkdir -p $OUTPUT_DIR

/usr/bin/time -f $TIME_FORMAT -o $BOX_MNT_PNT/$SAMPLE_NAME/mapping.time \
 bwa_mem.pl -o $OUTPUT_DIR \
 -r $REF_BASE/genome.fa \
 -s $SAMPLE_NAME \
 -t $CPU \
 -mt $CPU \
 $ADD_ARGS \
 $INPUT_DIR/*

# run any post-exec step
echo -e "\nRun POST_EXEC: `date`"
for i in "${POST_EXEC[@]}"; do
  set -x
  $i
  set +x
done

echo -e "\nWorkflow end: `date`"
