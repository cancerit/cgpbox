FROM  ubuntu:16.04

MAINTAINER  keiranmraine@gmail.com

ENV CGPBOX_VERSION 2.1.0

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="$CGPBOX_VERSION" \
      description="The CGP somatic calling pipeline 'in-a-box'"

USER  root

ADD build/apt-build.sh build/
ADD build/opt-build.sh build/

RUN bash build/apt-build.sh

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

RUN bash build/opt-build.sh

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu
USER    ubuntu
WORKDIR /home/ubuntu
RUN     echo "options(bitmapType='cairo')" > /home/ubuntu/.Rprofile

#ENTRYPOINT $OPT/bin/runCgp.sh
