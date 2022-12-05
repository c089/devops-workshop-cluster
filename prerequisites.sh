#!/bin/bash

set -e +x

SHOULD_EXIT_BECAUSE_OF_MISSING_DEPENDENCY=0

command_exists() {
    local COMMAND="$1"
    local INSTALL_GUIDE="$2"
    if ! command -v "$COMMAND" > /dev/null; then
	echo "Install '${COMMAND}' ( see ${INSTALL_GUIDE} )"
	SHOULD_EXIT_BECAUSE_OF_MISSING_DEPENDENCY=1
    fi
}

has_helm_repo() {
    local NAME="$1"
    local URL="$2"
	set +e
	helm repo list -o json | jq -e ".[] | select(.name == \"${NAME}\" and .url == \"${URL}\")" > /dev/null
    if [ $? -ne 0 ]
    then
        echo "helm repo add ${NAME} ${URL}"
        SHOULD_EXIT_BECAUSE_OF_MISSING_DEPENDENCY=1
    fi
	set -e
}

command_exists "docker-compose" "https://docs.docker.com/compose/"
command_exists "kubectl" "https://kubernetes.io/docs/tasks/tools/"
command_exists "jq" "https://stedolan.github.io/jq/"
command_exists "k3d" "https://k3d.io/v5.4.6/#installation"
command_exists "helm" "https://helm.sh/docs/intro/install/"
command_exists "mkcert" "https://github.com/FiloSottile/mkcert"
command_exists "argo" "https://argoproj.github.io/argo-workflows/quick-start/#install-the-argo-workflows-cli"
command_exists "argocd" "https://argo-cd.readthedocs.io/en/stable/getting_started/#2-download-argo-cd-cli"
command_exists "logcli" "https://grafana.com/docs/loki/latest/tools/logcli/"

has_helm_repo "traefik" "https://traefik.github.io/charts"
has_helm_repo "prometheus-community" "https://prometheus-community.github.io/helm-charts"
has_helm_repo "grafana" "https://grafana.github.io/helm-charts"
has_helm_repo "argo" "https://argoproj.github.io/argo-helm"
has_helm_repo "gitea-charts" "https://dl.gitea.io/charts/"

if [ "${SHOULD_EXIT_BECAUSE_OF_MISSING_DEPENDENCY}" -ne 0 ];
then
    echo ""
    echo "You need to install the dependencies listed above to continue."
    exit 1
fi
