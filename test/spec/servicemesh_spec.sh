Include spec/support.sh

Describe 'Service Mesh'
  CURL_POD=smoke-test-curl-$(date +%s)
  setup() {
    ls
    kubectl apply -f "$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_fixture.yaml"
    kubectl wait --for=condition=Available deployment servicemesh-spec

    kubectl run  --annotations="openservicemesh.io/sidecar-injection=enabled" --restart=Never --image alpine/curl:3.14 ${CURL_POD} --command sleep infinity
    kubectl wait --for=condition=Ready pod ${CURL_POD}
  }
  cleanup() {
    kubectl delete pod ${CURL_POD} --wait=false
    kubectl delete -f "$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_fixture.yaml"
  }
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "ingress: runs traffic into service mesh"
    When call curl -s -I "https://servicemesh-spec.k3d.local.profitbricks.net/bench"
    The line 1 of output should include "200"
    The output should include "server: envoy"
  End

  It "service-to-service: allows pods in the default namespace to talk to each other"
    When call kubectl exec ${CURL_POD} -c ${CURL_POD} -- curl -s -I "http://servicemesh-spec/bench"
    The status should be success
    The output should include "200 OK"
    The output should include "server: envoy"
  End

  It "egress: allows pods in the default namespace to talk to external services"
    When call kubectl exec ${CURL_POD} -c ${CURL_POD} -- curl -s -I "http://example.com"
    The status should be success
    The output should include "200 OK"
  End
End
