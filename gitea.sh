#!/bin/sh
set -x
username="developer"
reponame="hello-service"

admin_auth='gitea_admin:r8sA8CPHD9!bt6d' 
user_auth="${username}:${username}"
curl -H "Content-Type: application/json" \
  -d '{"email": "'${username}'@k3d.localhost", "password": "'${username}'", "username": "'${username}'", "must_change_password": false }' \
  -u "${admin_auth}" \
  https://gitea.k3d.localhost/api/v1/admin/users

curl -H "Content-Type: application/json" \
  -X POST \
  -d '{"auto_init": false, "default_branch": "main", "name": "'${reponame}'", "private": false}' \
  -u "${user_auth}" \
  https://gitea.k3d.localhost/api/v1/user/repos/

# TODO: push only the example service, not infrastructure to that repository
#       maybe have two repositories as per argocd "best practices"?
git remote add "gitea-${username}" "https://${user_auth}@gitea.k3d.localhost/${username}/${reponame}"
git push "gitea-${username}"
