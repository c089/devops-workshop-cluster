#!/bin/bash

set -e +x

SHOULD_EXIT_AFTER_RUNNING_OTHER_TESTS=0

command_exists() {
    local COMMAND="$1"
    local INSTALL_GUIDE="$2"
    if ! command -v "$COMMAND" > /dev/null; then
	echo "Install '${COMMAND}' ( see ${INSTALL_GUIDE} )"
	SHOULD_EXIT_AFTER_RUNNING_OTHER_TESTS=1
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
        SHOULD_EXIT_AFTER_RUNNING_OTHER_TESTS=1
    fi
	set -e
}


try_ping_host() {
    local HOST="$1"
    ping -c1 -q "$HOST" -W1 > /dev/null
    local RETVAL=$?
    if [ "$RETVAL" -ne 0 ];
    then
        echo "🟥 $HOST"
        return $RETVAL
    else
        echo "✅ $HOST"
        return 0
    fi
}

can_resolve_local_domain() {
    local DOMAIN_SUFFIX="local.profitbricks.net"
    set +e
    try_ping_host "gitea.k3d.$DOMAIN_SUFFIX"
    try_ping_host "hello.k3d.$DOMAIN_SUFFIX"
    try_ping_host "random_name.$DOMAIN_SUFFIX"
    local RETVAL=$?
    set -e

    if [ "$RETVAL" -ne 0 ];
    then
        echo "Could not resolve some domains to 127.0.0.1. Your router might be preventing DNS-rebinds."
        echo "You have the following options:"
        echo " - Specify a DNS server that resolves hosts to 127.0.0.1, like 1.1.1.1, 8.8.8.8 or 8.8.4.4"
        echo " - Enable DNSMasq (NetworkManager/Linux) and add a manual entry for those domains (see https://gist.github.com/ju1ius/944ad78f4db9188cd3cafc171aab8b98)"
        SHOULD_EXIT_AFTER_RUNNING_OTHER_TESTS=1
    fi
}

command_exists "shellspec" "https://github.com/shellspec/shellspec#installation"
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
has_helm_repo "osm" "https://openservicemesh.github.io/osm"
has_helm_repo "linkerd" "https://helm.linkerd.io/stable"
has_helm_repo "linkerd-smi" "https://linkerd.github.io/linkerd-smi"

can_resolve_local_domain

if [ "${SHOULD_EXIT_AFTER_RUNNING_OTHER_TESTS}" -ne 0 ];
then
    echo ""
    echo "You need to install the dependencies listed above to continue."
    exit 1
fi
