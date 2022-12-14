Include spec/support.sh

Describe 'Service Mesh'
  CURL_POD=smoke-test-curl-$(date +%s)
  CURL_NO_MESH_POD=smoke-test-curl-no-mesh-$(date +%s)
  setup() {
    kubectl apply -f "$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_fixture.yaml"
    kubectl wait --for=condition=Available deployment servicemesh-spec

    kubectl run  --annotations="linkerd.io/inject=enabled" --restart=Never \
      --image alpine/curl:3.14 ${CURL_POD} --command sleep infinity
    kubectl run  --annotations="linkerd.io/inject=disabled" --restart=Never \
      --image alpine/curl:3.14 ${CURL_NO_MESH_POD} --command sleep infinity

    kubectl wait --for=condition=Ready pod ${CURL_POD}
    kubectl wait --for=condition=Ready pod ${CURL_NO_MESH_POD}
  }
  cleanup() {
    kubectl delete pod ${CURL_POD} --wait=false
    kubectl delete pod ${CURL_NO_MESH_POD} --wait=false
    kubectl delete -f "$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_fixture.yaml"
  }
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "ingress: runs traffic into service mesh"
    When call curl -s "https://servicemesh-spec.k3d.local.profitbricks.net"
    The status should be success
    # NOTE: the traefik/whoami image replies with the HTTP request headers it
    # received as it's body, which we can use to verify the requests have been
    # proxied
    The output should include "L5d-Client-Id: "
  End

  It "service-to-service: allows meshed pods in the default namespace to talk to each other"
    When call kubectl exec ${CURL_POD} -c ${CURL_POD} -- curl -s "http://servicemesh-spec"
    The status should be success
    The output should include "L5d-Client-Id: "
  End

  It "service-to-service: allows non-meshed pod in the default namespace to talk to meshed pod"
    When call kubectl exec ${CURL_NO_MESH_POD} -c ${CURL_NO_MESH_POD} -- curl -sI "http://servicemesh-spec"
    The status should be success
    The output should include "200 OK"
  End

  It "egress: allows pods in the default namespace to talk to external services"
    When call kubectl exec ${CURL_POD} -c ${CURL_POD} -- curl -s -I "http://example.com"
    The status should be success
    # todo: verify meshed pod goes through the mesh
    The output should include "200 OK"
  End
End
