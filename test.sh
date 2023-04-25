#!/usr/bin/env bash

# Script to run as a service

x=0

while true; do
  echo "[$x] $@"
  sleep 1
  x=$((x+1))
done

# vim: filetype=sh tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab