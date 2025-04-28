// SPDX-FileCopyrightText: © 2025 Clifford Weinmann <https://www.cliffordweinmann.com/>
// SPDX-License-Identifier: MIT-0

/*
 * Quick https://k6.io/ test script
 */
import { check, sleep } from 'k6';
import http from 'k6/http';
import { scenario, vu } from 'k6/execution';

export const options = {
  vus: 2000,
  iterations: 50000,
  duration: '10m',
};

// const baseurl = 'http://0.0.0.0:8080/';
const baseurl = 'http://10.224.138.140:30080/';

const urlpaths = ['index.html', 'index.json', 'index.csv', 'index.txt'];

export default function () {
  urlpaths.forEach(function(item, index) {
    let resp = http.get(baseurl + item);
    check(resp, {
      "Status is 200": (resp) => resp.status === 200,
    });
  });
}
