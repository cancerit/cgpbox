#!/bin/bash

set -uxe

rm -rf /tmp/downloads

mkdir -p /tmp/downloads $OPT/bin $OPT/etc $OPT/lib $OPT/share $OPT/site /tmp/hts_cache $R_LIBS

cd /tmp/downloads

# cgpBigWig
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpBigWig/archive/0.3.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro /tmp/hts_cache

# PCAP-core
curl -sSL -o master.zip --retry 10 https://github.com/ICGC-TCGA-PanCancer/PCAP-core/archive/v3.3.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro /tmp/hts_cache

# alleleCount
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/alleleCount/archive/v3.2.1.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# cgpNgsQc
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpNgsQc/archive/v1.3.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# cgpVcf
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpVcf/archive/v2.1.1.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# ascatNgs
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/ascatNgs/archive/v3.1.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# cgpPindel
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpPindel/archive/v2.0.8.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# VAGrENT
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/VAGrENT/archive/v3.1.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# cgpCaVEManPostProcessing
curl -sSL -o master.zip --retry 10  https://github.com/cancerit/cgpCaVEManPostProcessing/archive/1.6.6.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# cgpCaVEManWrapper
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpCaVEManWrapper/archive/1.9.10.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# grass
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/grass/archive/v2.1.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

# Add ssearch36 BRASS dep
curl -sSL -o tmp.tar.gz --retry 10 https://github.com/wrpearson/fasta36/releases/download/v36.3.8d_13Apr16/fasta-36.3.8d-linux64.tar.gz
mkdir  /tmp/downloads/fasta
tar -C /tmp/downloads/fasta --strip-components 2 -zxf tmp.tar.gz
cp /tmp/downloads/fasta/bin/ssearch36 $OPT/bin/.
rm -rf /tmp/downloads/fasta

###
# Install the R support, cleanup, then BRASS
# Seems counter intuitive but this keeps the install step a little smaller,
# the intermediate cleanup is to ensure that the image remains small

# BRASS Rsupport
curl -sSL -o master.zip --retry 10 https://github.com/cancerit/BRASS/archive/v5.1.6.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip
cd /tmp/downloads/distro/Rsupport
#./setupR.sh $OPT 1
Rscript libInstall.R $R_LIBS
cd /tmp/downloads

# BRASS, using same download as Rsupport
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf master.zip /tmp/downloads/distro

curl -sSL https://raw.githubusercontent.com/cancerit/cgpbox/$CGPBOX_BRANCH/build/scripts/analysisWGS.sh > $OPT/bin/analysisWGS.sh
curl -sSL https://raw.githubusercontent.com/cancerit/cgpbox/$CGPBOX_BRANCH/build/scripts/mapping.sh > $OPT/bin/mapping.sh
curl -sSL https://raw.githubusercontent.com/cancerit/cgpbox/$CGPBOX_BRANCH/build/scripts/getRef.sh > $OPT/bin/getRef.sh
curl -sSL https://raw.githubusercontent.com/cancerit/cgpbox/$CGPBOX_BRANCH/build/scripts/progress.sh > $OPT/bin/progress.sh

chmod ugo+x $OPT/bin/analysisWGS.sh $OPT/bin/mapping.sh $OPT/bin/getRef.sh $OPT/bin/progress.pl

cp -r /tmp/downloads/cgpbox/site $OPT/site
mkdir -p $OPT/site/data
chmod -R ugo+rwx $OPT/site/data/

rm -rf /tmp/downloads/cgpbox

rm -rf /tmp/downloads
