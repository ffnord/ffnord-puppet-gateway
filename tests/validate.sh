#!/bin/bash

if [ $# -lt 1 ];then
  echo "$0 .pp-files"
  exit 1
fi

for manifest in $*;do
  echo "Validiere $manifest"
  puppet parser validate $manifest
  puppet-lint --no-80chars-check --no-autoloader_layout-check --with-filename $manifest
done
