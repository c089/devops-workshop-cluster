#!/bin/sh
set -eux
GITEA_URL="https://gitea.k3d.local.profitbricks.net"

CLONES_DIR=$(mktemp -d)
git clone ${GITEA_URL}/developer/deployment.git $CLONES_DIR/deployment
git clone ${GITEA_URL}/developer/service.git $CLONES_DIR/service
echo "Cloned to ${CLONES_DIR}".

# Trigger initial build an deploy of the workshop service
argocd app create \
  --dest-namespace default \
  -f "${CLONES_DIR}/deployment/argocd-application.yaml"
argo submit \
  -n argo \
  --serviceaccount argo-workflow \
  --wait \
  "${CLONES_DIR}/service/argo-workflow-cicd.yaml"
