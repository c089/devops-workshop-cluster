#!/bin/sh
echo "
Service URL username password
------- --- -------- --------
Grafana https://grafana.k3d.localhost admin password
ArgoCD https://argocd.k3d.localhost admin password
Gitea https://gitea.k3d.localhost gitea_admin password
Gitea https://gitea.k3d.localhost developer password
"|column -t -s " "
