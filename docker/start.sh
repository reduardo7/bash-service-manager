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
TEST_PID="$!"

sleep 30

kill -9 $TEST_PID
./example-service stop

echo "Finish!"

# vim: filetype=sh tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab