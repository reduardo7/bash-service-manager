#!/usr/bin/env bash

# Only as example for docker container

set -ex

./example-service start
echo "Ready!"

(
  sleep 3
  ./example-service status
  sleep 1
  ./example-service tail
) &

sleep 30
echo "Finish!"

# vim: filetype=sh tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab