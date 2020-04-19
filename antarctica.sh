#!/bin/bash

ANT_DEBUG=${ANT_DEBUG:-false}

ROOT=$(dirname "$(realpath "$0")")

lua -e "__dbg, __rootdir = $ANT_DEBUG, '$ROOT'" \
  -e "package.path=package.path..';$ROOT/lua/?.lua;$ROOT/?.lua'" \
  -e "package.cpath=package.cpath..';$ROOT/?.so'" \
  -l antarctica \
  $@ 
