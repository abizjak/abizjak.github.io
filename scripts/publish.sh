#!/bin/bash
# should be run from the directory where _site is a subdirectory. Otherwise it will not work.
# rsync -r _site/ abizjak@fh.cs.au.dk:/users/abizjak/public_html_cs/

CONFIG=_config.yml

if [ -f $CONFIG ]; then
    jekyll build
    scp -r _site/* abizjak/
else
    echo -n "Script run from directory: "
    pwd
    echo "This directory does is not the root of a jekyll project."
fi


