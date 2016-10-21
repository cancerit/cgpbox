#!/bin/bash

TIME_FORMAT='command:%C\nreal:%e\nuser:%U\nsys:%S\ntext:%Xk\ndata:%Dk\nmax:%Mk\n';

set -e

echo -e "\nStart workflow: `date`\n"

if [ -z ${CPU+x} ]; then
  CPU=`grep -c ^processor /proc/cpuinfo`
fi

TMP=$BOX_MNT_PNT/output/tmp
mkdir -p $TMP

declare -a PRE_EXEC
declare -a POST_EXEC

echo "Loading user options..."
source $HOME/map.params

set -u
echo -e "\tSAMPLE_NAME : $SAMPLE_NAME"
echo -e "\tINPUT_DIR : $INPUT_DIR"
echo -e "\tPROTOCOL : $PROTOCOL"
echo -e "\tSPECIES : $SPECIES"
echo -e "\tASSEMBLY : $ASSEMBLY"
echo -e "\tREF_BASE : $REF_BASE"
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

/usr/bin/time -f $TIME_FORMAT -o $BOX_MNT_PNT/mapping/$SAMPLE_NAME.time \
 bwa_mem.pl -o $BOX_MNT_PNT/mapping/$SAMPLE_NAME \
 -r $REF_BASE/genome.fa \
 -s $SAMPLE_NAME \
 -t $CPU \
 -mt $CPU \
 $INPUT_DIR/*

# run any post-exec step
echo -e "\nRun POST_EXEC: `date`"
for i in "${POST_EXEC[@]}"; do
  set -x
  $i
  set +x
done

echo -e "\nWorkflow end: `date`"
