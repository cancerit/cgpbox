#!/bin/bash

set -ue

echo "Loading user options..."
source /datastore/input/run.params

echo -e "\tNAME_MT : $NAME_MT"
echo -e "\tNAME_WT : $NAME_WT"
echo -e "\tBAM_MT : $BAM_MT"
echo -e "\tBAM_WT : $BAM_WT"

if [ "${PRE_EXEC}x" -ne "x" ]; then
  echo -e "\tPRE_EXEC : $PRE_EXEC"
else
  PRE_EXEC="echo 'No PRE_EXEC defined'"
fi

echo -e "\nStart workflow: `date`\n"

# run any pre-exec step before attempting to access BAMs
# logically the pre-exec could be pulling them
`$PRE_EXEC`

CPU=`grep -c ^processor /proc/cpuinfo`

TMP='/datastore/output/tmp'

mkdir -p $TMP

BAM_MT_TMP=$TMP/$NAME_MT.bam
BAM_WT_TMP=$TMP/$NAME_WT.bam

ln -s $BAM_MT $BAM_MT_TMP
ln -s $BAM_WT $BAM_WT_TMP
ln -s $BAM_MT.bai $BAM_MT_TMP.bai
ln -s $BAM_WT.bai $BAM_WT_TMP.bai

if [ !-e "${BAM_MT}.bas" ]; then
  echo -e "Generate BAS $NAME_MT: `date`\n"
  bam_stats -i $BAM_MT_TMP -o $BAM_MT_TMP.bas
else
  ln -s $BAM_MT.bas $BAM_MT_TMP.bas
fi

if [ !-e "${BAM_WT}.bas" ]; then
  echo -e "Generate BAS $NAME_WT: `date`\n"
  bam_stats -i $BAM_WT_TMP -o $BAM_WT_TMP.bas
else
  ln -s $BAM_WT.bas $BAM_WT_TMP.bas
fi

echo -e "Genotype Check start: `date`\n"

set -x
compareBamGenotypes.pl \
 -o /datastore/output/$NAME_WT/genotyped \
 -nb $BAM_WT \
 -j /datastore/output/$NAME_WT/genotyped/result.json \
 -tb $BAM_MT
set +x

echo -e "ASCAT start: `date`\n"

set -x
ascat.pl \
 -o /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat \
 -t $BAM_MT \
 -n $BAM_WT \
 -s /datastore/reference_files/ascat/SnpLocus.tsv \
 -sp /datastore/reference_files/ascat/SnpPositions.tsv \
 -sg /datastore/reference_files/ascat/SnpGcCorrections.tsv \
 -r /datastore/reference_files/genome.fa \
 -q 20 \
 -g L \
 -rs Human \
 -ra GRCh37 \
 -pr WGS \
 -pl ILLUMINA \
 -c $CPU
set +x

echo -e "VerifyBam Tumour start: `date`\n"

set -x
verifyBamHomChk.pl -d 25 \
 -o /datastore/output/$NAME_MT/contamination \
 -b $BAM_MT \
 -a /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/${NAME_MT}.copynumber.caveman.csv \
 -j /datastore/output/$NAME_MT/contamination/result.json
set +x

echo -e "VerifyBam Normal start: `date`\n"

set -x
verifyBamHomChk.pl -d 25 \
 -o /datastore/output/$NAME_WT/contamination \
 -b $BAM_WT \
 -j /datastore/output/$NAME_WT/contamination/result.json
set +x

echo -e "PINDEL start: `date`\n"

set -x
pindel.pl \
 -o /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel \
 -t $BAM_MT \
 -n $BAM_WT \
 -r /datastore/reference_files/genome.fa \
 -s /datastore/reference_files/pindel/simpleRepeats.bed.gz \
 -f /datastore/reference_files/pindel/genomicRules.lst \
 -g /datastore/reference_files/pindel/human.GRCh37.indelCoding.bed.gz \
 -u /datastore/reference_files/pindel/pindel_np.gff3.gz \
 -sf /datastore/reference_files/pindel/softRules.lst \
 -st WGS \
 -as GRCh37 \
 -sp Human \
 -e NC_007605,hs37d5,GL% \
 -c $CPU
set +x

# prep ascat output for caveman:

echo -e "CaVEMan prep: `date`\n"

set -x
ASCAT_CN="/datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/$NAME_MT.copynumber.caveman.csv"
perl -ne '@F=(split q{,}, $_)[1,2,3,4]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/norm.cn.bed
perl -ne '@F=(split q{,}, $_)[1,2,3,6]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/tum.cn.bed
set +x

echo -e "CaVEMan start: `date`\n"

set -x
caveman.pl \
 -r /datastore/reference_files/genome.fa.fai \
 -ig /datastore/reference_files/caveman/ucscHiDepth_0.01_merge1000_no_exon.tsv \
 -b /datastore/reference_files/caveman/flagging \
 -u /datastore/reference_files/caveman \
 -s HUMAN \
 -sa GRCh37 \
 -t $CPU \
 -st genomic \
 -in /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.germline.bed  \
 -tc $TMP/tum.cn.bed \
 -nc $TMP/norm.cn.bed \
 -tb $BAM_MT \
 -nb $BAM_WT \
 -o /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman
set +x

echo -e "BRASS start: `date`\n"

set -x
brass.pl -j 4 -k 4 -c $CPU \
 -e MT,GL%,hs37d5,NC_007605 \
 -d /datastore/reference_files/brass/ucscHiDepth_0.01_mrg1000_no_exon_coreChrs.bed.gz \
 -f /datastore/reference_files/brass/brass_np.groups.gz \
 -g /datastore/reference_files/genome.fa \
 -s HUMAN -as GRCh37 -pr WGS -pl ILLUMINA \
 -g_cache /datastore/reference_files/vagrent/e75/Homo_sapiens.GRCh37.75.vagrent.cache.gz \
 -vi /datastore/reference_files/brass/viral.1.1.genomic.fa \
 -mi /datastore/reference_files/brass/all_ncbi_bacteria.20150703 \
 -b /datastore/reference_files/brass/hs37d5_500bp_windows.gc.bed.gz \
 -t $BAM_MT \
 -n $BAM_WT \
 -a /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/*.copynumber.caveman.csv \
 -ss /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/*.samplestatistics.csv \
 -o /datastore/output/${NAME_MT}_vs_${NAME_WT}/brass
set +x

echo -e "Annot CaVEMan start: `date`\n"

# annotate caveman
rm -f /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf.gz*
set -x
AnnotateVcf.pl -t -c /datastore/reference_files/vagrent/e75/Homo_sapiens.GRCh37.75.vagrent.cache.gz \
 -i /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.flagged.muts.vcf.gz \
 -o /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf
set +x

echo -e "Annot CaVEMan start: `date`\n"

# annotate pindel
rm -f /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
set -x
AnnotateVcf.pl -t -c /datastore/reference_files/vagrent/e75/Homo_sapiens.GRCh37.75.vagrent.cache.gz \
 -i /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.flagged.vcf.gz \
 -o /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf
set +x

echo -e "Workflow end: `date`\n"
