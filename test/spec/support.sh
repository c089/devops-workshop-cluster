CURL_ARGS="--fail -s -o /dev/null -w %{json} --insecure"
CURL_ARGS_API="-s --insecure"
CURL_SSL_VERIFY_SUCCESS=0 # as documented in man 1 curl

# usage: The output should satisfy value -gt 5"
value() { test "${value:?}" "$1" "$2" ; }
# usge: The output should satisfy formula "value > 5"
formula() { value=${formula:?} ; [ $(($1)) -eq 1 ] ; }

curl_property() { echo "$2" | jq -r ".${1}"; }
redirect_url() { curl_property "redirect_url" "$1" ; }
http_code() { curl_property "http_code" "$1" ; }
ssl_verify_result() { curl_property "ssl_verify_result" "$1" ; }
grafana_loki_query_instant() {
  # execute a loki metric query through grafana via an "instant" type query and
  # return the expected singular result
  # FIXME password static
  #
  curl $CURL_ARGS_API "https://grafana.k3d.localhost/api/ds/query" \
    -H 'content-type: application/json' \
    -u admin:password \
    -H 'origin: https://grafana.k3d.localhost' \
    --data-raw '{
                  "queries": [
                    {
                      "datasource": { "uid": "loki", "type": "loki" },
                      "queryType": "instant",
                      "expr": "'$1'"
                    }
                  ],
                  "to": "now"
                }' | jq '.results.A.frames[0].data.values[1][0]'
}
grafana_prometheus_query_instant() {
  # execute a loki metric query through grafana via an "instant" type query and
  # return the expected singular result
  curl $CURL_ARGS_API "https://grafana.k3d.localhost/api/ds/query" \
    -H 'content-type: application/json' \
    -u admin:password \
    -H 'origin: https://grafana.k3d.localhost' \
    --data-raw '{
                  "queries": [
                    {
                      "datasource": { "uid": "prometheus", "type": "prometheus" },
                      "queryType": "timeSeriesQuery",
                      "instant": true,
                      "range": false,
                      "expr": "'$1'"
                    }
                  ],
                  "from" :"now",
                  "to": "now"
                }'
}

grafana_api_call() {
  curl $CURL_ARGS_API "https://grafana.k3d.localhost$1" \
    -H 'content-type: application/json' \
    -u admin:password \
    -H 'origin: https://grafana.k3d.localhost'
}

query_loki() {
  LOKI_ADDR=https://loki.k3d.localhost/ logcli query --quiet "$1"
}
run_in_cluster() {
  image="$1"; shift;
  smoke_test_pod="cluster-smoke-test-$(date +%s)"
  kubectl run \
    --restart=Never \
    --image "${image}" \
    ${smoke_test_pod} \
    --command sleep infinity
  kubectl wait --for="condition=Ready" pod ${smoke_test_pod}
  kubectl exec ${smoke_test_pod} -c ${smoke_test_pod} -- $@
}
