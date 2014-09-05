#!/bin/bash

# Used to test and push TriBITS on any machine assoicated iwth Trilinos
# development.
#
# NOTE: The only purpose for this script is to allow the generic
# checkin-test.py script to find the TriBITSProj base directoyr.

EXTRA_ARGS=$@

#
# By default, this script assumes the directory structure
#
# Trilinos.base/
#     Trilinos/
#         TriBITS/
#     BUILDS/
#         TRIBITS_CHECKIN
#
# To change this structure, just run with:
#
#   env TRIBITS_SRC_DIR=<some-dir> ./checkin-test.sh --do-all
#

if [ "$TRIBITS_SRC_DIR" == "" ] ; then
  TRIBITS_SRC_DIR=../../Trilinos/TriBITS
fi

TRIBITS_SRC_DIR_ABS=$(readlink -f $TRIBITS_SRC_DIR)

$TRIBITS_SRC_DIR_ABS/checkin-test.py \
--src-dir=${TRIBITS_SRC_DIR_ABS} \
-j16 \
$EXTRA_ARGS  