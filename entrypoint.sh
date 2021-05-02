#!/bin/bash -i

# Fail on errors.
# set -im

# Make sure .bashrc is sourced
. /root/.bashrc

# Allow the workdir to be set using an env var.
# Useful for CI pipiles which use docker for their build steps
# and don't allow that much flexibility to mount volumes
SRCDIR=$1

PYPI_URL=$2

PYPI_INDEX_URL=$3

WORKDIR=${SRCDIR:-.}

SPEC_FILE=${4:-*.spec}

TYPE=amd64

/root/.pyenv/shims/python -m pip install --upgrade pip wheel setuptools

#
# In case the user specified a custom URL for PYPI, then use
# that one, instead of the default one.
#
if [[ "$PYPI_URL" != "https://pypi.python.org/" ]] || \
   [[ "$PYPI_INDEX_URL" != "https://pypi.python.org/simple" ]]; then
    # the funky looking regexp just extracts the hostname, excluding port
    # to be used as a trusted-host.
    mkdir -p /root/.pip
    echo "[global]" > /root/.pip/pip.conf
    echo "index = $PYPI_URL" >> /root/.pip/pip.conf
    echo "index-url = $PYPI_INDEX_URL" >> /root/.pip/pip.conf
    echo "trusted-host = $(echo $PYPI_URL | perl -pe 's|^.*?://(.*?)(:.*?)?/.*$|$1|')" >> /root/.pip/pip.conf

    echo "Using custom pip.conf: "
    cat /root/.pip/pip.conf
fi

cd $WORKDIR

if [ -f $5 ]; then
    /root/.pyenv/shims/pip install -r $5
fi # [ -f $5 ]

/root/.pyenv/shims/pyinstaller --clean -y --dist ./dist/linux/$TYPE --workpath /tmp $SPEC_FILE

chown -R --reference=. ./dist/linux/$TYPE

apt-get install -y file

ls ./dist/linux/$TYPE | echo "::set-output name=location::$WORKDIR/dist/linux/$TYPE/$(< /dev/stdin)"
ls ./dist/linux/$TYPE | echo "::set-output name=filename::$(< /dev/stdin)"

echo "::set-output name=content_type::$(ls ./dist/linux/$TYPE | file --mime-type ./dist/linux/$TYPE/$(< /dev/stdin) | awk '//{ print $2 }')"

