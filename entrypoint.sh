#!/bin/bash

# Fail on errors.
set -e

# Make sure .bashrc is sourced
. /root/.bashrc

# Allow the workdir to be set using an env var.
# Useful for CI pipiles which use docker for their build steps
# and don't allow that much flexibility to mount volumes
SRCDIR=$1

PYPI_URL=$2

PYPI_INDEX_URL=$3

WORKDIR=${SRCDIR:-/src}

SPEC_FILE=${4:-*.spec}

TYPE=win64
FILE_DIR=dist/windows/$TYPE


python -m pip install --upgrade pip wheel setuptools

#
# In case the user specified a custom URL for PYPI, then use
# that one, instead of the default one.
#
if [[ "$PYPI_URL" != "https://pypi.python.org/" ]] || \
   [[ "$PYPI_INDEX_URL" != "https://pypi.python.org/simple" ]]; then
    # the funky looking regexp just extracts the hostname, excluding port
    # to be used as a trusted-host.
    mkdir -p /wine/drive_c/users/root/pip
    echo "[global]" > /wine/drive_c/users/root/pip/pip.ini
    echo "index = $PYPI_URL" >> /wine/drive_c/users/root/pip/pip.ini
    echo "index-url = $PYPI_INDEX_URL" >> /wine/drive_c/users/root/pip/pip.ini
    echo "trusted-host = $(echo $PYPI_URL | perl -pe 's|^.*?://(.*?)(:.*?)?/.*$|$1|')" >> /wine/drive_c/users/root/pip/pip.ini

    echo "Using custom pip.ini: "
    cat /wine/drive_c/users/root/pip/pip.ini
fi

cd $WORKDIR

if [ -f $5 ]; then
    pip install -r $5
fi # [ -f $5 ]


pyinstaller --clean -y --dist $FILE_DIR --workpath /tmp $SPEC_FILE
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
