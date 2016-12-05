#!/bin/bash

# about to do some parallel work...
declare -A do_parallel

TIME_FORMAT='command:%C\nreal:%e\nuser:%U\nsys:%S\ntext:%Xk\ndata:%Dk\nmax:%Mk\n';

# declare function to run parallel processing
run_parallel () {
  # adapted from: http://stackoverflow.com/a/18666536/4460430
  local max_concurrent_tasks=$1
  local -A pids=()

  for key in "${!do_parallel[@]}"; do
    while [ $(jobs 2>&1 | grep -c Running) -ge "$max_concurrent_tasks" ]; do
      sleep 1 # gnu sleep allows floating point here...
    done

    CMD='/usr/bin/time -f '$TIME_FORMAT' -o '$OUTPUT_DIR'/'$key'.time '${do_parallel[$key]}

    echo -e "\tStarting $key"
    set -x
    $CMD &
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

set -e

echo -e "\nStart workflow: `date`\n"

declare -a PRE_EXEC
declare -a POST_EXEC

if [ -z ${PARAM_FILE+x} ] ; then
  PARAM_FILE=$HOME/run.params
fi
echo "Loading user options from: $PARAM_FILE"
if [ ! -f $PARAM_FILE ]; then
  echo -e "\tERROR: file indicated by PARAM_FILE not found: $PARAM_FILE" 1>&2
  exit 1
fi
source $PARAM_FILE

TMP=$OUTPUT_DIR/tmp
mkdir -p $TMP

if [ -z ${CPU+x} ]; then
  CPU=`grep -c ^processor /proc/cpuinfo`
fi

# create area which allows monitoring site to be started, not actively updated until after PRE-EXEC completes
#cp -r /opt/wtsi-cgp/site $OUTPUT_DIR/site

echo -e "\tBAM_MT : $BAM_MT"
echo -e "\tBAM_WT : $BAM_WT"

if [ ${#PRE_EXEC[@]} -eq 0 ]; then
  PRE_EXEC='echo No PRE_EXEC defined'
fi

if [ ${#POST_EXEC[@]} -eq 0 ]; then
  POST_EXEC='echo No POST_EXEC defined'
fi

set -u
mkdir -p $OUTPUT_DIR

# run any pre-exec step before attempting to access BAMs
# logically the pre-exec could be pulling them
if [ ! -f $OUTPUT_DIR/pre-exec.done ]; then
  echo -e "\nRun PRE_EXEC: `date`"

  for i in "${PRE_EXEC[@]}"; do
    set -x
    $i
    { set +x; } 2> /dev/null
  done
  touch $OUTPUT_DIR/pre-exec.done
fi

## get sample names from BAM headers
NAME_MT=`samtools view -H $BAM_MT | perl -ne 'if($_ =~ m/^\@RG/) {($sm) = $_ =~m/\tSM:([^\t]+)/; print "$sm\n";}' | uniq`
NAME_WT=`samtools view -H $BAM_WT | perl -ne 'if($_ =~ m/^\@RG/) {($sm) = $_ =~m/\tSM:([^\t]+)/; print "$sm\n";}' | uniq`

echo -e "\tNAME_MT : $NAME_MT"
echo -e "\tNAME_WT : $NAME_WT"

#echo -e '\nStarting monitoring...'
#progress.pl $OUTPUT_DIR $NAME_MT $NAME_WT $TIMEZONE $OUTPUT_DIR/site/data/progress.js >& $OUTPUT_DIR/monitor.log&

BAM_MT_TMP=$TMP/$NAME_MT.bam
BAM_WT_TMP=$TMP/$NAME_WT.bam

ln -fs $BAM_MT $BAM_MT_TMP
ln -fs $BAM_WT $BAM_WT_TMP
ln -fs $BAM_MT.bai $BAM_MT_TMP.bai
ln -fs $BAM_WT.bai $BAM_WT_TMP.bai

echo "Setting up Parallel block 1"

if [ ! -f "${BAM_MT}.bas" ]; then
  echo -e "\t[Parallel block 1] BAS $NAME_MT added..."
  do_parallel[bas_MT]="bam_stats -i $BAM_MT_TMP -o $BAM_MT_TMP.bas"
else
  ln -fs $BAM_MT.bas $BAM_MT_TMP.bas
fi

if [ ! -f "${BAM_WT}.bas" ]; then
  echo -e "\t[Parallel block 1] BAS $NAME_WT added..."
  do_parallel[bas_WT]="bam_stats -i $BAM_WT_TMP -o $BAM_WT_TMP.bas"
else
  ln -fs $BAM_WT.bas $BAM_WT_TMP.bas
fi

echo "Starting Parallel block 1: `date`"
run_parallel $CPU do_parallel

# unset and redeclare the parallel array ready for block 2
unset do_parallel
declare -A do_parallel

echo -e "\nSetting up Parallel block 2"
echo -e "\t[Parallel block 2] ASCAT added..."

echo -e "\t[Parallel block 2] Pindel added..."
do_parallel[pindel]="pindel.pl \
 -o $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/pindel \
 -r $REF_BASE/genome.fa \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -s $REF_BASE/pindel/simpleRepeats.bed.gz \
 -u $REF_BASE/pindel/pindel_np.gff3.gz \
 -f $REF_BASE/pindel/${PROTOCOL}_Rules.lst \
 -g $REF_BASE/vagrent/codingexon_regions.indel.bed.gz \
 -st $PROTOCOL \
 -as $ASSEMBLY \
 -sp '$SPECIES' \
 -e $PINDEL_EXCLUDE \
 -b $REF_BASE/pindel/HiDepth.bed.gz \
 -c $CPU \
 -sf $REF_BASE/pindel/softRules.lst"

# Need empty cn bed for blanket settings
touch $TMP/empty.cn.bed
# Need a germline bed even though not used
echo '#comment' >  $TMP/empty.germline.bed

echo -e "\t[Parallel block 2] CaVEMan added..."
do_parallel[CaVEMan]="caveman.pl \
 -r $REF_BASE/genome.fa.fai \
 -ig $REF_BASE/caveman/HiDepth.tsv \
 -b $REF_BASE/caveman/flagging \
 -ab $REF_BASE/vagrent \
 -u $REF_BASE/caveman \
 -s '$SPECIES' \
 -sa $ASSEMBLY \
 -t $CPU \
 -st $PROTOCOL \
 -in $TMP/empty.germline.bed \
 -tc $TMP/empty.cn.bed \
 -nc $TMP/empty.cn.bed \
 -td 5 -nd 2 \
 -tb $BAM_MT_TMP \
 -nb $BAM_WT_TMP \
 -c $REF_BASE/caveman/flagging/flag.vcf.config.ini \
 -f $REF_BASE/caveman/flagging/flag.to.vcf.convert.ini \
 -o $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/caveman"

echo "Starting Parallel block 2: `date`"
run_parallel $CPU do_parallel

# unset and redeclare the parallel array ready for block 3
unset do_parallel
declare -A do_parallel

# annotate pindel
rm -f $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
echo -e "\t[Parallel block 3] Pindel_annot added..."
do_parallel[Pindel_annot]="AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
 -i $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.flagged.vcf.gz \
 -o $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf"

# annotate caveman
rm -f $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf.gz*
echo -e "\t[Parallel block 3] CaVEMan_annot added..."
do_parallel[CaVEMan_annot]="AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
 -i $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.flagged.muts.vcf.gz \
 -o $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf"

echo "Starting Parallel block 3: `date`"
run_parallel $CPU do_parallel

# clean up log files
rm -rf $OUTPUT_DIR/${NAME_MT}_vs_${NAME_WT}/*/logs

echo 'Package results'
tar -C $OUTPUT_DIR -zcf result_${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.tar.gz ${NAME_MT}_vs_${NAME_WT} ${NAME_MT} ${NAME_WT}

# run any post-exec step
echo -e "\nRun POST_EXEC: `date`"
for i in "${POST_EXEC[@]}"; do
  set -x
  $i
  set +x
done

echo -e "\nWorkflow end: `date`"
