import http from 'k6/http';
import {Counter} from 'k6/metrics';

const requestsPerServer = new Counter('servers');

export default function () {
  const response = http.get('https://trafficsplit-spec.k3d.local.profitbricks.net/api');
  const {hostname} = JSON.parse(response.body);
  requestsPerServer.add(1, { hostname });
}
