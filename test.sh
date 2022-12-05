#!/bin/sh

CLUSTER_DIR=$(dirname "$0")

cd "${CLUSTER_DIR}/test"
shellspec "$@"
