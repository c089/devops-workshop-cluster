Include spec/support.sh

Describe 'k3d development cluster'

  Describe "Traefik"
    It "redirects http to https"
      When call curl $CURL_ARGS -I "http://any-service.k3d.localhost/"
      The status should be success
      The result of "redirect_url()" should equal "https://any-service.k3d.localhost/"
    End

    It "uses a valid certificate"
      When call curl ${CURL_ARGS} --no-fail --no-insecure https://any-service.k3d.localhost/
      The status should be success
      The result of "ssl_verify_result()" should equal ${CURL_SSL_VERIFY_SUCCESS}
    End

    It "exposes the Traefik dashboard"
      When call curl $CURL_ARGS https://traefik-dashboard.k3d.localhost/dashboard/
      The status should be success
      The result of "http_code()" should equal "200"
    End
  End

  Describe "Private Docker Registry"
    It "is accessible to workloads in the cluster"
      run_in_cluster() {
        image="$1"; shift;
        kubectl run \
          --rm \
          --wait \
          --attach \
          --restart=Never \
          --image "${image}" \
          registry-smoke-test \
          --command $@
      }

      registry_name="registry"
      local_tag="localhost:5000/busybox:latest"
      cluster_tag="${registry_name}:5000/busybox:latest"

      docker pull busybox:latest
      docker tag busybox:latest ${local_tag}
      docker push ${local_tag}

      When call run_in_cluster ${cluster_tag} /bin/echo woop!
      The status should be success
      The output should include "woop!"
    End
  End

  Describe "Gitea"
    It "exposes gitea web interface"
      When call curl $CURL_ARGS https://gitea.k3d.localhost/
      The status should be success
      The result of "http_code()" should equal "200"
    End

    It "created the example repository"
      When call curl $CURL_ARGS https://gitea.k3d.localhost/developer/hello-service
      The status should be success
      The result of "http_code()" should equal "200"
    End
  End

  Describe "Argo"
    It "exposes the argo-cd interface"
      When call curl $CURL_ARGS https://argocd.k3d.localhost/
      The status should be success
      The result of "http_code()" should equal "200"
    End

    It "exposes the argo-rollouts dashboard"
      When call curl $CURL_ARGS https://argo-rollouts.k3d.localhost/rollouts/
      The status should be success
      The result of "http_code()" should equal "200"
    End

    It "exposes the argo-workflows interface"
      When call curl $CURL_ARGS https://argo-workflows.k3d.localhost/workflows/
      The status should be success
      The result of "http_code()" should equal "200"
    End

    It "allows argo-rollouts to manage traefikservices"
      When run kubectl auth can-i \
        --namespace default \
        --as system:serviceaccount:argo-rollouts:argo-rollouts \
        get traefikservices.traefik.containo.us
      The status should be success
      The output should equal "yes"
    End

   It "allows argo-workflows to sync apps in argocd"
     When run argocd admin settings rbac can argo-workflows sync applications --namespace argocd
     The status should be success
     The output should equal "Yes"
    End
  End

  Describe "Prometheus"
    It "exposes the web interface"
      When call curl $CURL_ARGS https://prometheus.k3d.localhost/graph
      The status should be success
      The result of "http_code()" should equal "200"
    End

    It "has ony the watchdog alert firing"
      firing_alerts() {
        env echo "$1" | jq -r '.data.alerts | map(select (.state == "firing" )) | map (.labels.alertname) | join(",")'
      }
      When call curl $CURL_ARGS_API https://prometheus.k3d.localhost/api/v1/alerts
      The status should be success
      The result of "firing_alerts()" should equal "Watchdog"
    End

    It "exposes the blackbox interface"
      When call curl $CURL_ARGS https://prometheus-blackbox.k3d.localhost/
      The status should be success
      The result of "http_code()" should equal "200"
    End

    prometheus_blackbox_exporter_scrape_pools() {
      curl $CURL_ARGS_API https://prometheus.k3d.localhost/api/v1/targets | jq -r \
        '.data.activeTargets[] | select (.labels.service == "prometheus-blackbox-exporter") | .scrapePool'
    }

    It "scrapes the blackbox-exporter metrics"
      When call prometheus_blackbox_exporter_scrape_pools
      The output should include "serviceMonitor/observability/prometheus-blackbox-exporter/0"
    End

    It "scrapes the hello service"
      When call prometheus_blackbox_exporter_scrape_pools
      The output should include "serviceMonitor/observability/prometheus-blackbox-exporter-hello/0"
    End
  End

  Describe "Loki"
    It "can be queried using logcli"
      When call query_loki '{app="loki"}'
      The status should be success
      The lines of stdout should not equal "0"
    End
  End

  Describe "Grafana"
    grafana_datasources() { env echo "$1" | jq -r '.[].uid' ; }

    It "exposes the web interface"
      When call curl $CURL_ARGS https://grafana.k3d.localhost/
      The status should be success
      The result of "http_code()" should equal "302"
      The result of "redirect_url()" should equal "https://grafana.k3d.localhost/login"
    End

    It "has Loki configured as datasource"
      When call grafana_api_call '/api/datasources'
      The status should be success
      The result of "grafana_datasources()" should include "loki"
    End

    It "can query Loki"
      When call grafana_loki_query_instant 'count_over_time({app=\"loki\"}[15m])'
      The output should satisfy formula "value > 0"
    End

    It "has Prometheus configured datasource"
      When call grafana_api_call '/api/datasources'
      The status should be success
      The result of "grafana_datasources()" should include "prometheus"
    End

    It "can query Prometheus"
      extract_version_label() {
        env echo -n "$1" | jq -j \
          '.results.A.frames[0].schema.fields | map(select (.name == "Value")) | first | .labels.version'
      }
      When call grafana_prometheus_query_instant 'grafana_build_info'
      The result of "extract_version_label()" should equal "9.2.4"
    End

    It "has its log files aggregated"
      When call query_loki '{app="grafana", namespace="observability", container="grafana"} | logfmt | level = `info`'
      The status should be success
      The lines of stdout should not equal 0
    End

    It "does not log any errors"
      When call query_loki '{app="grafana", namespace="observability", container="grafana"} | logfmt | level = `error`'
      The status should be success
      The lines of stdout should equal 0
    End
  End

End
