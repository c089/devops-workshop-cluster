#!/bin/bash

set -euxo pipefail

argocd \
  login \
  argocd.k3d.localhost \
  --username admin \
  --password password
