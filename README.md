# cgpbox
The __cgpbox__ project encapsulates the core [Cancer Genome Project](http://www.sanger.ac.uk/science/groups/cancer-genome-project) analysis pipeline for Wholegenome NGS analysis from Illumina paired-end sequencing.

## Input requirements
__cgpbox__ expects to be provided with a pair of BAM files (one tumour, one normal) each:

* Mapped with BWA-mem
  * Having valid ReadGroup headers including LB and SN tags
  * See SAM/BAM specification [here](https://samtools.github.io/hts-specs/SAMv1.pdf) for more details.
* Duplicates marked.
* BAM indexes created.

### Data mapped in different fashion
Data mapped using a different algorithm _may_ process successfully however we are unlikely to be able to provide detailed support.

If you already have a mapped BAM you can re-map with all of the above handled for you using the `bwa_mem.pl` script which is part of [PCAP-core](https://github.com/ICGC-TCGA-PanCancer/PCAP-core).

## Primary analysis software

It incorporates the following _cancerit_ projects:

 * [cgpVcf](https://github.com/cancerit/cgpVcf)
 * [alleleCount](https://github.com/cancerit/alleleCount)
 * [cgpNgsQc](https://github.com/cancerit/cgpNgsQc)
 * [ascatNgs](https://github.com/cancerit/ascatNgs)
 * [cgpPindel](https://github.com/cancerit/cgpPindel)
 * [cgpCaVEManPostProcessing](https://github.com/cancerit/cgpCaVEManPostProcessing)
 * [CaVEMan](https://github.com/cancerit/CaVEMan)
 * [cgpCaVEManWrapper](https://github.com/cancerit/cgpCaVEManWrapper)
 * [VAGrENT](https://github.com/cancerit/VAGrENT)
 * [grass](https://github.com/cancerit/grass)
 * [BRASS](https://github.com/cancerit/BRASS)

### Dependancies

Additionally these have dependancies on the following software packages which may have different license restrictions to the _cancerit_ packages:

* [PCAP-core](https://github.com/ICGC-TCGA-PanCancer/PCAP-core) - maintained by _cancerit_
* [kentUtils](https://github.com/ENCODE-DCC/kentUtils)
* [BWA](https://github.com/lh3/bwa)
* [biobambam2](https://github.com/gt1/biobambam2)
* [htslib](https://github.com/samtools/htslib)
* [samtools (legacy)](https://github.com/samtools/samtools)
* [tabix](https://github.com/samtools/tabix)
* [bedtools2](https://github.com/arq5x/bedtools2)
* [verifyBamID](https://github.com/statgen/verifyBamID)
* [blat](https://genome.ucsc.edu/FAQ/FAQblat.html)
* [velvet](https://github.com/dzerbino/velvet)
* [exonerate](https://github.com/nathanweeks/exonerate)
* [fasta36](https://github.com/wrpearson/fasta36) - only `ssearch36`



LICENCE
=======
Copyright (c) 2016 Genome Research Ltd.

Author: Cancer Genome Project <cgpit@sanger.ac.uk>

This file is part of cgpbox.

cgpbox is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

1. The usage of a range of years within a copyright statement contained within
this distribution should be interpreted as being equivalent to a list of years
including the first and last year specified and all consecutive years between
them. For example, a copyright statement that reads ‘Copyright (c) 2005, 2007-
2009, 2011-2012’ should be interpreted as being identical to a statement that
reads ‘Copyright (c) 2005, 2007, 2008, 2009, 2011, 2012’ and a copyright
statement that reads ‘Copyright (c) 2005-2012’ should be interpreted as being
identical to a statement that reads ‘Copyright (c) 2005, 2006, 2007, 2008,
2009, 2010, 2011, 2012’."