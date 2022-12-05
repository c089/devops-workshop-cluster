#!/bin/bash

set -euxo pipefail

argocd \
  login \
  argocd.k3d.localhost \
  --username admin \
  --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o json|jq .data.password -j | base64 -d)
