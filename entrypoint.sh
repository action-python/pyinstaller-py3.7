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

TYPE=i386
FILE_DIR=dist/linux/$TYPE


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
fi # [ -f requirements.txt ]

/root/.pyenv/shims/pyinstaller --clean -y --dist $FILE_DIR --workpath /tmp $SPEC_FILE

chown -R --reference=. $FILE_DIR

apt-get install -y file

FILES_COUNT=`ls $FILE_DIR | wc -l`

if [ $FILES_COUNT = 1 ]
then
    DEF_FILE_NAME=`ls $FILE_DIR`
fi

RENAME=${6:-$DEF_FILE_NAME}

if [ $DEF_FILE_NAME != $RENAME ]
then
    mv $FILE_DIR/$DEF_FILE_NAME $FILE_DIR/$RENAME
fi

if [ $FILES_COUNT = 1 ]
then
    echo "::set-output name=location::$WORKDIR/$FILE_DIR/$RENAME"
    echo "::set-output name=filename::$RENAME"
    echo "::set-output name=content_type::$(ls $FILE_DIR | file --mime-type $FILE_DIR/$(< /dev/stdin) | awk '//{ print $2 }')"
else
    echo "::set-output name=location::$WORKDIR/$FILE_DIR"
    echo "::set-output name=filename::NULL"
    echo "::set-output name=content_type::NULL"
fi
