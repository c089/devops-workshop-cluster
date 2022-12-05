#!/bin/sh
set -x
username="developer"
reponame="hello-service"

admin_auth='gitea_admin:r8sA8CPHD9!bt6d'
user_auth="${username}:${username}"
# curl -H "Content-Type: application/json" \
#   -d '{"email": "'${username}'@k3d.localhost", "password": "'${username}'", "username": "'${username}'", "must_change_password": false }' \
#   -u "${admin_auth}" \
#   https://gitea.k3d.localhost/api/v1/admin/users

mirror_repository() {
  local NAME=$1
  local URL=$2

  local PAYLOAD=$(
    cat <<EOF
    {
      "clone_addr": "$2",
      "repo_name": "$1",
      "pull_requests": false,
      "issues": false,
      "wiki": false,
      "releases": false,
      "labels": false,
      "milestones": false,
      "mirror": false
    }
EOF
  )

  curl -v -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    -u "${user_auth}" \
    https://gitea.k3d.localhost/api/v1/repos/migrate
}

mirror_repository "service" "https://github.com/c089/devops-workshop-service.git"
mirror_repository "deployment" "https://github.com/c089/devops-workshop-deployment.git"
