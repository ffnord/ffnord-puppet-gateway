#!/bin/bash

if [ $# -lt 1 ];then
  echo "$0 .pp-files"
  exit 1
fi

for manifest in $*;do
  echo "Validiere $manifest"
  puppet parser validate $manifest
  puppet-lint --no-arrow_on_right_operand_line-check --no-parameter_order-check --no-names_containing_dash-check --no-documentation-check --no-arrow_alignment-check --no-140chars-check --no-autoloader_layout-check --with-filename $manifest
done
