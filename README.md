| # | DevOps | Workshop - Infrastructure |

This repository contains all necessary resources to bootstrap a self-contained kubernetes cluster for the workshop.

**Your setup is only completed if `./test.sh` completes successfully!**

## Getting Started

The install script will check if you have all necessary prerequisites installed.

```sh
./create.sh
```

## URLs

| Service             | Endpoint                                           | Username    | Password |
| ------------------- | -------------------------------------------------- | ----------- | -------- |
| Grafana             | https://grafana.k3d.localhost                      | admin       | password |
| Loki (for logcli)   | https://loki.k3d.localhost                         | -           | -        |
| Argo CD             | https://argocd.k3d.localhost                       | admin       | password |
| Argo Workflows      | https://argo-workflows.k3d.localhost               | -           | -        |
| Argo Rollouts       | https://argo-rollouts.k3d.localhost                | -           | -        |
| Gitea               | https://gitea.k3d.localhost                        | gitea_admin | password |
| Gitea               | https://gitea.k3d.localhost                        | developer   | password |
| Prometheus          | https://prometheus.k3d.localhost                   |             |          |
| Prometheus Blackbox | https://prometheus-blackbox.k3d.localhost          |             |          |
| Traefik Dashboard   | https://traefik-dashboard.k3d.localhost/dashboard/ |             |          |
