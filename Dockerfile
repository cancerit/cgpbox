FROM  ubuntu:16.04

MAINTAINER  keiranmraine@gmail.com

ARG cgpbox_ver=develop

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="$cgpbox_ver" \
      description="The CGP somatic calling pipeline 'in-a-box'"

USER  root

ENV CGPBOX_VERSION $cgpbox_ver
ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

ADD build/apt-build.sh build/
ADD build/opt-build.sh build/

RUN bash build/apt-build.sh
RUN bash build/opt-build.sh

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu
USER    ubuntu
WORKDIR /home/ubuntu
RUN     echo "options(bitmapType='cairo')" > /home/ubuntu/.Rprofile

ENTRYPOINT /bin/bash

#ENTRYPOINT $OPT/bin/runCgp.sh
