FROM  ubuntu:14.04

MAINTAINER  keiranmraine@gmail.com

ENV CGPBOX_VERSION 2.1.0

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="$CGPBOX_VERSION" \
      description="The CGP somatic calling pipeline 'in-a-box'"

USER  root

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5

RUN apt-get -yq update && \
    apt-get -yq install libreadline6-dev build-essential autoconf software-properties-common python-software-properties \
      curl libcurl4-openssl-dev nettle-dev zlib1g-dev libncurses5-dev \
      libexpat1-dev python unzip libboost-dev libboost-iostreams-dev \
      libpstreams-dev libglib2.0-dev gfortran libcairo2-dev \
      git bsdtar libwww-perl openjdk-7-jdk time s3cmd libgoogle-perftools-dev && \
    apt-get clean

RUN mkdir -p /tmp/downloads $OPT/bin $OPT/etc $OPT/lib $OPT/share $OPT/site /tmp/hts_cache

WORKDIR /tmp/downloads

# cgpBigWig
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpBigWig/archive/0.3.0.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro /tmp/hts_cache

# PCAP-core
RUN curl -sSL -o master.zip --retry 10 https://github.com/ICGC-TCGA-PanCancer/PCAP-core/archive/v3.3.1.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro /tmp/hts_cache

# alleleCount
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/alleleCount/archive/v3.2.1.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# cgpNgsQc
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpNgsQc/archive/v1.3.0.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# cgpVcf
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpVcf/archive/v2.1.1.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# ascatNgs
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/ascatNgs/archive/v3.1.0.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# cgpPindel
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpPindel/archive/v2.0.8.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# VAGrENT
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/VAGrENT/archive/v3.2.0.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# cgpCaVEManPostProcessing
RUN curl -sSL -o master.zip --retry 10  https://github.com/cancerit/cgpCaVEManPostProcessing/archive/1.6.6.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# cgpCaVEManWrapper
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/cgpCaVEManWrapper/archive/1.9.10.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# grass
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/grass/archive/v2.1.0.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

# Add ssearch36 BRASS dep
RUN curl -sSL -o tmp.tar.gz --retry 10 https://github.com/wrpearson/fasta36/releases/download/v36.3.8d_13Apr16/fasta-36.3.8d-linux64.tar.gz && \
    mkdir  /tmp/downloads/fasta && \
    tar -C /tmp/downloads/fasta --strip-components 2 -zxf tmp.tar.gz && \
    cp /tmp/downloads/fasta/bin/ssearch36 $OPT/bin/. && \
    rm -rf /tmp/downloads/fasta

###
# Install the R support, cleanup, then BRASS
# Seems counter intuitive but this keeps the install step a little smaller,
# the intermediate cleanup is to ensure that the image remains small

# BRASS Rsupport
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/BRASS/archive/v5.1.6.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro/Rsupport && \
    ./setupR.sh $OPT 1 && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $OPT/R-lib

# BRASS
RUN curl -sSL -o master.zip --retry 10 https://github.com/cancerit/BRASS/archive/v5.1.6.zip && \
    mkdir /tmp/downloads/distro && \
    bsdtar -C /tmp/downloads/distro --strip-components 1 -xf master.zip && \
    cd /tmp/downloads/distro && \
    ./setup.sh $OPT && \
    cd /tmp/downloads && \
    rm -rf master.zip /tmp/downloads/distro

COPY scripts/runCgp.sh $OPT/bin/runCgp.sh
COPY scripts/getRef.sh $OPT/bin/getRef.sh
COPY scripts/progress.pl $OPT/bin/progress.pl
RUN chmod ugo+x $OPT/bin/runCgp.sh $OPT/bin/getRef.sh $OPT/bin/progress.pl

COPY site $OPT/site
RUN mkdir -p $OPT/site/data && chmod -R ugo+rwx $OPT/site/data/

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' cgpbox && chsh -s /bin/bash && mkdir -p /home/cgpbox
USER    cgpbox
WORKDIR /home/cgpbox
RUN     echo "options(bitmapType='cairo')" > /home/cgpbox/.Rprofile

ENTRYPOINT $OPT/bin/runCgp.sh
