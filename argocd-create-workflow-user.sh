#!/bin/bash

set -euxo pipefail

$(dirname "$0")/argocd-login.sh

kubectl patch configmap -n argocd argocd-cm -p '{ "data": { "accounts.argo-workflows": "apiKey" } }'
ARGO_WORKFLOWS_TOKEN=$(argocd account generate-token --account argo-workflows)

kubectl create -n default secret generic argocd-argo-workflows-token --from-literal=auth-token="$ARGO_WORKFLOWS_TOKEN"
