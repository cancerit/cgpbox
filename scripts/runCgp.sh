#!/bin/bash

set -ue

echo -n "Start workflow: ";date

CPU=`grep -c ^processor /proc/cpuinfo`

TMP='/datastore/output/tmp'
NAME_MT='HCC1143'
NAME_WT='HCC1143_BL'
BAM_MT='/datastore/input/HCC1143.bam'
BAM_WT='/datastore/input/HCC1143_BL.bam'
mkdir -p $TMP

echo -n "Genotype Check start: ";date

set -x
compareBamGenotypes.pl \
 -o /datastore/output/$NAME_WT/genotyped \
 -nb $BAM_WT \
 -j /datastore/output/$NAME_WT/genotyped/result.json \
 -tb $BAM_MT
set +x

echo -n "ASCAT start: ";date

set -x
ascat.pl \
 -o /datastore/output/$NAME_MT/ascat \
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

echo -n "VerifyBam Tumour start: ";date

set -x
verifyBamHomChk.pl -d 25 \
 -o /datastore/output/$NAME_MT/contamination \
 -b $BAM_MT \
 -a /datastore/output/$NAME_MT/ascat/${NAME_MT}.copynumber.caveman.csv \
 -j /datastore/output/$NAME_MT/contamination/result.json
set +x

echo -n "VerifyBam Normal start: ";date

set -x
verifyBamHomChk.pl -d 25 \
 -o /datastore/output/$NAME_WT/contamination \
 -b $BAM_WT \
 -j /datastore/output/$NAME_WT/contamination/result.json
set +x

echo -n "PINDEL start: ";date

set -x
pindel.pl \
 -o /datastore/output/$NAME_MT/pindel \
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

echo -n "CaVEMan prep: ";date

set -x
ASCAT_CN="/datastore/output/$NAME_MT/ascat/$NAME_MT.copynumber.caveman.csv"
perl -ne '@F=(split q{,}, $_)[1,2,3,4]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/norm.cn.bed
perl -ne '@F=(split q{,}, $_)[1,2,3,6]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/tum.cn.bed
set +x

echo -n "CaVEMan start: ";date

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
 -in /datastore/output/$NAME_MT/pindel/${NAME_MT}_vs_${NAME_WT}.germline.bed  \
 -tc $TMP/tum.cn.bed \
 -nc $TMP/norm.cn.bed \
 -tb $BAM_MT \
 -nb $BAM_WT \
 -o /datastore/output/$NAME_MT/caveman
set +x

echo -n "BRASS start: ";date

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
 -a /datastore/output/$NAME_MT/ascat/*.copynumber.caveman.csv \
 -ss /datastore/output/$NAME_MT/ascat/*.samplestatistics.csv \
 -o /datastore/output/$NAME_MT/brass
set +x

echo -n "Annot CaVEMan start: ";date

# annotate caveman
rm -f /datastore/output/$NAME_MT/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf.gz*
set -x
AnnotateVcf.pl -t -c /datastore/reference_files/vagrent/e75/Homo_sapiens.GRCh37.75.vagrent.cache.gz \
 -i /datastore/output/$NAME_MT/caveman/${NAME_MT}_vs_${NAME_WT}.flagged.muts.vcf.gz \
 -o /datastore/output/$NAME_MT/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf
set +x

echo -n "Annot CaVEMan start: ";date

# annotate pindel
rm -f /datastore/output/$NAME_MT/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
set -x
AnnotateVcf.pl -t -c /datastore/reference_files/vagrent/e75/Homo_sapiens.GRCh37.75.vagrent.cache.gz \
 -i /datastore/output/$NAME_MT/pindel/${NAME_MT}_vs_${NAME_WT}.flagged.vcf.gz \
 -o /datastore/output/$NAME_MT/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf
set +x

echo -n "Workflow end: ";date
