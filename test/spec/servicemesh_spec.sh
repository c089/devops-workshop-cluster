Include spec/support.sh

Describe 'Service Mesh'

  Describe "Meshing"
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

    It "passes it's own validaton"
      When call linkerd check
      The status should be success
      The output should include "Status check results are √"
      The output should include "linkerd-smi"
      The output should include "linkerd-viz"
    End

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

  Describe "Traffic Splitting"
    BeforeAll 'setup_trafficsplit'
    AfterAll 'teardown_trafficsplit'

    setup_trafficsplit() {
      k6results=`mktemp`
      kubectl apply -f "$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_trafficsplit_fixture.yaml"
      kubectl wait --for=condition=Available deployment trafficsplit-spec-v1
      kubectl wait --for=condition=Available deployment trafficsplit-spec-v2
      sleep 2 # todo active wait?
    }

    teardown_trafficsplit() {
      kubectl delete -f "$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_trafficsplit_fixture.yaml"
    }

    generate_traffic() {
      k6script="$(dirname ${SHELLSPEC_SPECFILE})/servicemesh_trafficsplit_load.js"
      cat $k6script | docker run --network host --rm -i \
        grafana/k6 run \
          --vus 100 --iterations 10000 \
          --insecure-skip-tls-verify \
          --quiet --out csv=- -
    }

    v1_answers() { grep -c "trafficsplit-spec-v1" $k6results ; }
    v2_answers() { grep -c "trafficsplit-spec-v2" $k6results ; }

    It "implements TrafficSplit"
      generate_traffic > $k6results
      The result of function v1_answers should satisfy formula "value > 8500 && value < 10000"
      The result of function v2_answers should satisfy formula "value > 0 && value < 1500"
    End
  End
End
