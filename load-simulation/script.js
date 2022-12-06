import http from "k6/http";
import { sleep } from "k6";

const API_BASE_URL = "https://hello.k3d.localhost";

export default function () {
  http.batch([["GET", `${API_BASE_URL}/`]]);

  sleep(1);
}
