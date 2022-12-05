#!/bin/sh
argo_password() {
  kubectl get secret -n argocd argocd-initial-admin-secret -o json | \
    jq -j .data.password | \
    base64 -d
}

echo "
Service URL username password
------- --- -------- --------
Grafana https://grafana.k3d.localhost admin prom-operator
ArgoCD https://argocd.k3d.localhost admin $(argo_password)
"|column -t -s " "
