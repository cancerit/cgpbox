# Use or build for Docker

For Docker use you should use the pre-generated docker image found here:

https://quay.io/repository/wtsicgp/cgp_in_a_box

Following the [README](README.md) should handle this for you.

If you want to work with a more bleeding edge version you can download the current repo branch with:

```
curl -O -sSL https://github.com/cancerit/cgpbox/archive/<BRANCH_NAME>.tar.gz
tar zxvf <BRANCH_NAME>.tar.gz
cd cgpbox-<BRANCH_NAME>
dockder build .
```

Remember to set the image instance to be this image (not the quay.io version) when starting the job.

# Bare-metal or non-container
This method can be used if you have root access to the system, or more likely want to build an image of another type (such as OpenStack) which adding Docker on top of is not necessary/sensible.  This approach is likely to give better performance/throughput.

## Example using Ubuntu Xenial
You can take the apt-get steps directly from the Docker file for Ubuntu Trusty.

Here is an example of a 'user-data' input for OpenStack:

```
#!/bin/bash

set -ue

# base packages

###
# do anything specific to your system here
# e.g. security certificates, pushing public keys to known_hosts
###

apt-get -yq update
apt-get -yq install curl

export CGPBOX_BRANCH='feature/add_mapping'

curl -sSL https://raw.githubusercontent.com/cancerit/cgpbox/$CGPBOX_BRANCH/scripts/Xenial-build.sh > /tmp/Xenial-build.sh
bash /tmp/Xenial-build.sh
```

Following this log into the host and execute the script [opt-build.sh](scripts/opt-build.sh).

Once this completes you will have a pre-configured instance that can be exported as per the documentation for your virtualisation framework.
