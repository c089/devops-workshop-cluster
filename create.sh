#!/bin/bash
set -ex

DOMAIN=k3d.local.profitbricks.net
CLUSTER_DIR=$(dirname "$0")
source "${CLUSTER_DIR}/prerequisites.sh"

# create and install a default certificate
keyfile=$(mktemp)
certfile=$(mktemp)
mkcert -install -cert-file $certfile -key-file $keyfile localhost host.k3d.internal ${DOMAIN} \*.${DOMAIN}
kubectl create secret -n kube-system tls tls-default-certificate --cert $certfile --key $keyfile

# make sure registries are up
docker-compose -f "${CLUSTER_DIR}/local-pullthrough-registries.docker-compose.yaml" up -d

# create cluster
k3d cluster create \
  --agents 2 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  --registry-config "$CLUSTER_DIR/local-pullthrough-registries.k3d-registries.yaml" \
  --registry-create registry:0.0.0.0:5000

# Install Linkerd
helm install linkerd-crds linkerd/linkerd-crds \
  -n linkerd --create-namespace

step-cli certificate create root.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca --no-password --insecure
step-cli certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca --not-after 8760h --no-password --insecure \
  --ca ca.crt --ca-key ca.key

helm install linkerd-control-plane \
  -n linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  linkerd/linkerd-control-plane

rm ca.crt ca.key issuer.crt issuer.key

helm install \
  --namespace linkerd-viz \
  --create-namespace \
  --atomic \
  linkerd-viz linkerd/linkerd-viz \
  --set dashboard.enforcedHostRegexp="linkerd-viz.${DOMAIN}"
kubectl apply -f linkerd-viz-ingressroute.yaml

# install prometheus, alertmanager, grafana
helm upgrade --install --atomic --create-namespace \
	--namespace observability \
  --values "${CLUSTER_DIR}/kube-prometheus-stack-values.yaml" \
	kube-prometheus-stack prometheus-community/kube-prometheus-stack

# configure traefik
helm_deploy_status() {
	helm status -o json -n kube-system traefik 2> /dev/null | jq -j '.info.status'
}

echo "waiting for traefik..."
until [[ $(helm_deploy_status) = "deployed" ]]; do
  echo -n "."
	sleep 1
done

kubectl delete deployment -n kube-system traefik # workaround "cannot ugprade" issue
helm upgrade -n kube-system --values "${CLUSTER_DIR}/traefik-values.yaml" traefik traefik/traefik

# wait for trafik to install ingressroute crd
echo "waiting for crd..."
until kubectl get crd | grep ingressroute; do
  echo -n "."
	sleep 1
done

# replace traefik ingressroute
kubectl delete ingressroute -n kube-system traefik-dashboard
kubectl apply -f "${CLUSTER_DIR}/traefik-ingressroute.yaml"

kubectl apply -f "${CLUSTER_DIR}/kube-prometheus-stack-ingressroutes.yaml"
# install loki and prommtail
helm upgrade --install --atomic --create-namespace \
  --values "${CLUSTER_DIR}/loki-stack-values.yaml" \
	--namespace observability \
  loki-stack grafana/loki-stack
kubectl apply -f "${CLUSTER_DIR}/loki-ingressroute.yaml"

# install blackbox-exporter
kubectl create configmap \
  -n observability \
  certificate-host.k3d.internal \
  --from-file "host.k3d.internal.crt=$certfile"

helm upgrade --install --atomic \
  --namespace observability \
  --values "${CLUSTER_DIR}/prometheus-blackbox-exporter-values.yaml" \
  prometheus-blackbox-exporter \
  prometheus-community/prometheus-blackbox-exporter
kubectl apply -f "${CLUSTER_DIR}/prometheus-blackbox-exporter-ingressroute.yaml"
kubectl apply -f "${CLUSTER_DIR}/grafana-dashboard-blackbox.yaml"


kubectl create namespace argo

# install gitea
helm upgrade --install --atomic --create-namespace \
  --namespace gitea \
  gitea \
  gitea-charts/gitea \
  --values "${CLUSTER_DIR}/gitea-values.yaml"
kubectl apply -n gitea -f "${CLUSTER_DIR}/gitea-ingressroute.yaml"
${CLUSTER_DIR}/gitea-clone-workshop-repositories.sh

# install argo-workflows
helm upgrade --install \
  -n argo \
  argo-workflows \
  argo/argo-workflows \
  --values "${CLUSTER_DIR}/argo-workflows-values.yaml"
kubectl apply -f "${CLUSTER_DIR}/argo-workflows-ingressroute.yaml"

# install argocd
helm install \
  -n argocd \
  --create-namespace \
  argo-cd \
  argo/argo-cd \
  --values "${CLUSTER_DIR}/argocd-values.yaml"
kubectl apply -f "${CLUSTER_DIR}/argocd-ingressroute.yaml"
kubectl patch configmap -n argocd \
  argocd-rbac-cm --patch-file ${CLUSTER_DIR}/argocd-configmap-rbac.yaml

# install argo-rollouts
helm install \
  -n argo-rollouts \
  --create-namespace \
  --values "${CLUSTER_DIR}/argo-rollouts-values.yaml" \
  argo-rollouts argo/argo-rollouts
kubectl apply -f "${CLUSTER_DIR}/argo-rollouts-ingressroute.yaml"
kubectl apply -f "${CLUSTER_DIR}/argo-rollouts-rbac.yaml"

# cleanup
rm $keyfile
rm $certfile

# Wait for login to succeed, then create workflow user in argocd
until $(dirname "$0")/argocd-login.sh; do
  sleep 1
done
${CLUSTER_DIR}/argocd-create-workflow-user.sh


rm ${CLUSTER_DIR}/test/.shellspec-quick.log || true
${CLUSTER_DIR}/test.sh -q || true
until ${CLUSTER_DIR}/test.sh -q -r; do
	sleep 5
done
${CLUSTER_DIR}/test.sh


echo "🥳 All done. Admin credentials and services:"
${CLUSTER_DIR}/show-credentials.sh
