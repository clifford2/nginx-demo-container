/*
 * Quick https://k6.io/ test script
 */
import { check, sleep } from 'k6';
import http from 'k6/http';
import { scenario, vu } from 'k6/execution';

export const options = {
  vus: 1000,
  iterations: 10000,
  duration: '10m',
};

// const baseurl = 'http://0.0.0.0:8080/';
const baseurl = 'http://host.containers.internal:8080/';

const urlpaths = ['index.html', 'index.json', 'index.csv', 'index.txt'];

export default function () {
  urlpaths.forEach(function(item, index) {
    let resp = http.get(baseurl + item);
    check(resp, {
      "Status is 200": (resp) => resp.status === 200,
    });
  });
}
