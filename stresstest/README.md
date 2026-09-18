# Quick Stress Tests

Code in this directory:

- `k6-stress.js`: Quick https://k6.io/ test script
- `stresstest.sh`: Quick and dirty shell script to run a bunch of requests

Alternately, try [ApacheBench](https://httpd.apache.org/docs/2.4/programs/ab.html):

```sh
ab -n 100000 -c 1000 http://0.0.0.0:8080/index.html | tee benchmark.log
```
