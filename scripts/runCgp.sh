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

    CMD='/usr/bin/time -f '$TIME_FORMAT' -o '$BOX_MNT_PNT'/output/'$key'.time '${do_parallel[$key]}

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

if [ -z ${CPU+x} ]; then
  CPU=`grep -c ^processor /proc/cpuinfo`
fi

TMP=$BOX_MNT_PNT/output/tmp
mkdir -p $TMP

declare -a PRE_EXEC
declare -a POST_EXEC

echo "Loading user options..."
source $BOX_MNT_PNT/run.params

echo "Starting monitoring..."
cp -r /opt/wtsi-cgp/site $BOX_MNT_PNT/site
progress.pl $BOX_MNT_PNT $NAME_MT $NAME_WT $TIMEZONE $BOX_MNT_PNT/site/data/progress.js >& $BOX_MNT_PNT/monitor.log&

echo -e "\tNAME_MT : $NAME_MT"
echo -e "\tNAME_WT : $NAME_WT"
echo -e "\tBAM_MT : $BAM_MT"
echo -e "\tBAM_WT : $BAM_WT"

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

REF_BASE=$BOX_MNT_PNT/$CGPBOX_VERSION/reference_files

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

echo -e "\t[Parallel block 1] Genotype Check added..."
do_parallel[geno_MT]="compareBamGenotypes.pl \
 -o $BOX_MNT_PNT/output/$NAME_WT/genotyped \
 -nb $BAM_WT_TMP \
 -j $BOX_MNT_PNT/output/$NAME_WT/genotyped/result.json \
 -tb $BAM_MT_TMP"

echo -e "\t[Parallel block 1] VerifyBam Normal added..."
do_parallel[verify_WT]="verifyBamHomChk.pl -d 25 \
 -o $BOX_MNT_PNT/output/$NAME_WT/contamination \
 -b $BAM_WT_TMP \
 -j $BOX_MNT_PNT/output/$NAME_WT/contamination/result.json"


echo -e "\t[Parallel block 1] Get refset added..."
do_parallel[get_refset]="getRef.sh "


echo "Starting Parallel block 1: `date`"
run_parallel $CPU do_parallel

# unset and redeclare the parallel array ready for block 2
unset do_parallel
declare -A do_parallel

echo -e "\nSetting up Parallel block 2"
echo -e "\t[Parallel block 2] ASCAT added..."

do_parallel[ascat]="ascat.pl \
 -o $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/ascat \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -sg $REF_BASE/ascat/SnpGcCorrections.tsv \
 -r $REF_BASE/genome.fa \
 -q 20 \
 -g L \
 -rs '$SPECIES' \
 -ra $ASSEMBLY \
 -pr $PROTOCOL \
 -pl ILLUMINA \
 -c $CPU"

echo -e "\t[Parallel block 2] Pindel added..."
do_parallel[pindel]="pindel.pl \
 -o $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/pindel \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -r $REF_BASE/genome.fa \
 -s $REF_BASE/pindel/simpleRepeats.bed.gz \
 -f $REF_BASE/pindel/genomicRules.lst \
 -g $REF_BASE/pindel/indelCoding.bed.gz \
 -u $REF_BASE/pindel/pindel_np.gff3.gz \
 -sf $REF_BASE/pindel/softRules.lst \
 -b $REF_BASE/brass/HiDepth.bed.gz \
 -st $PROTOCOL \
 -as $ASSEMBLY \
 -sp '$SPECIES' \
 -e NC_007605,hs37d5,GL% \
 -c $CPU"

echo "Starting Parallel block 2: `date`"
run_parallel $CPU do_parallel

# prep ascat output for caveman:

echo -e "CaVEMan prep: `date`"

set -x
ASCAT_CN="$BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/ascat/$NAME_MT.copynumber.caveman.csv"
perl -ne '@F=(split q{,}, $_)[1,2,3,4]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/norm.cn.bed
perl -ne '@F=(split q{,}, $_)[1,2,3,6]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/tum.cn.bed
set +x

# unset and redeclare the parallel array ready for block 3
unset do_parallel
declare -A do_parallel

echo -e "\nSetting up Parallel block 3"
echo -e "\t[Parallel block 3] VerifyBam Tumour added..."

do_parallel[verify_MT]="verifyBamHomChk.pl -d 25 \
 -o $BOX_MNT_PNT/output/$NAME_MT/contamination \
 -b $BAM_MT_TMP \
 -a $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/ascat/${NAME_MT}.copynumber.caveman.csv \
 -j $BOX_MNT_PNT/output/$NAME_MT/contamination/result.json"

# annotate pindel
rm -f $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
echo -e "\t[Parallel block 3] Pindel_annot added..."
do_parallel[Pindel_annot]="AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
 -i $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.flagged.vcf.gz \
 -o $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf"

echo -e "\t[Parallel block 3] CaVEMan added..."
do_parallel[CaVEMan]="caveman.pl \
 -r $REF_BASE/genome.fa.fai \
 -ig $REF_BASE/caveman/HiDepth.tsv \
 -b $REF_BASE/caveman/flagging \
 -u $REF_BASE/caveman \
 -s '$SPECIES' \
 -sa $ASSEMBLY \
 -t $CPU \
 -st genomic \
 -in $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.germline.bed  \
 -tc $TMP/tum.cn.bed \
 -nc $TMP/norm.cn.bed \
 -tb $BAM_MT_TMP \
 -nb $BAM_WT_TMP \
 -o $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/caveman"

echo -e "\t[Parallel block 3] BRASS added..."
do_parallel[BRASS]="brass.pl -j 4 -k 4 -c $CPU \
 -d $REF_BASE/brass/HiDepth.bed.gz \
 -f $REF_BASE/brass/brass_np.groups.gz \
 -g $REF_BASE/genome.fa \
 -s '$SPECIES' -as $ASSEMBLY -pr $PROTOCOL -pl ILLUMINA \
 -g_cache $REF_BASE/vagrent/vagrent.cache.gz \
 -vi $REF_BASE/brass/viral.1.1.genomic.fa \
 -mi $REF_BASE/brass/all_ncbi_bacteria.20150703 \
 -b $REF_BASE/brass/500bp_windows.gc.bed.gz \
 -ct $REF_BASE/brass/CentTelo.tsv \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -ss $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/ascat/*.samplestatistics.txt \
 -o $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/brass"

echo "Starting Parallel block 3: `date`"
run_parallel $CPU do_parallel
echo

echo -e "Annot CaVEMan start: `date`"
# annotate caveman
rm -f $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf.gz*
set -x
AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
 -i $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.flagged.muts.vcf.gz \
 -o $BOX_MNT_PNT/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf
set +x

echo -e "Annot CaVEMan end: `date`"

cp -r $BOX_MNT_PNT/site $BOX_MNT_PNT/output/.
cd $BOX_MNT_PNT
echo 'Package results'
tar -zcf result_${NAME_MT}_vs_${NAME_WT}.tar.gz output

# run any post-exec step
echo -e "\nRun POST_EXEC: `date`"
for i in "${POST_EXEC[@]}"; do
  set -x
  $i
  set +x
done

echo -e "\nWorkflow end: `date`"
