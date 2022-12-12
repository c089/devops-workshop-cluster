#!/bin/bash

set -euxo pipefail

argocd \
  login \
  argocd.k3d.local.profitbricks.net \
  --username admin \
  --password password
