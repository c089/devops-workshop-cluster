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
| Grafana             | https://grafana.k3d.local.profitbricks.net                      | admin       | password |
| Loki (for logcli)   | https://loki.k3d.local.profitbricks.net                         | -           | -        |
| Argo CD             | https://argocd.k3d.local.profitbricks.net                       | admin       | password |
| Argo Workflows      | https://argo-workflows.k3d.local.profitbricks.net               | -           | -        |
| Argo Rollouts       | https://argo-rollouts.k3d.local.profitbricks.net                | -           | -        |
| Gitea               | https://gitea.k3d.local.profitbricks.net                        | gitea_admin | password |
| Gitea               | https://gitea.k3d.local.profitbricks.net                        | developer   | password |
| Prometheus          | https://prometheus.k3d.local.profitbricks.net                   |             |          |
| Alertmanager        | https://alertmanager.k3d.local.profitbricks.net                 |             |          |
| Prometheus Blackbox | https://prometheus-blackbox.k3d.local.profitbricks.net          |             |          |
| Traefik Dashboard   | https://traefik-dashboard.k3d.local.profitbricks.net/dashboard/ |             |          |

## Alerting

To enable pushover notifications:

```
kubectl create secret generic pushover --from-literal=token=$PUSHOVER_TOKEN --from-literal=userkey=$PUSHOVER_USERKEY
kubectl apply -f alertmanager-pushover.yaml
```

Note these are currently limited to alerts from the default namespace, which
cannot be configured easily without upgrading prometheus-operator, but no new
updated helm chart exists, see

https://github.com/prometheus-operator/prometheus-operator/issues/3737
