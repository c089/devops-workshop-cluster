import { check } from 'k6';
import http from 'k6/http';
import {Counter} from 'k6/metrics';

const totalRequests = new Counter('servers');

export default function () {
  const response = http.get('https://trafficsplit-spec.k3d.local.profitbricks.net/api');
  check(response, { 'response code was 200': (res) => res.status == 200 });
  const body = response.json();
  const hostname = body.hostname;
  totalRequests.add(1, { hostname });
}
