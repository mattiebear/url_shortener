# Naive URL Shortener (v1) - Performance Analysis

This document contains load test results for the initial naive implementation of the URL shortener.

## Baseline Load Test

The baseline test establishes performance characteristics under light to moderate load conditions.

### Test Configuration

- **Duration**: 8 minutes total
- **Load Pattern**:
  - Warm up: 30s ramping to 5 users
  - Ramp: 2m ramping to 10 users
  - Sustained: 3m at 10 users (baseline)
  - Light spike: 1m ramping to 20 users
  - Hold: 1m at 20 users
  - Cool down: 30s ramping to 0 users

- **Traffic Mix**:
  - 15% URL creation requests
  - 80% redirect requests
  - 5% 404 testing (invalid codes)

### Results Summary

![Grafana Dashboard - Baseline Load Test](../tiny_url_v1/grafana_baseline.png)

#### Thresholds - All Passed ✓

- **Response Time**: 95th percentile < 200ms ✓ (actual: 132.58ms)
- **Response Time**: 99th percentile < 500ms ✓ (actual: 149.05ms)
- **Error Rate**: < 1% ✓ (actual: 0.00%)
- **Links Created**: > 0 ✓ (count: 300)
- **Successful Redirects**: > 0 ✓ (count: 1580)

#### Performance Metrics

**Custom Metrics**
```
create_link_duration...: avg=94.58ms  min=66ms   med=91ms   max=157ms   p(90)=118.1ms  p(95)=132.15ms
created_links..........: 300 (0.62/s)
redirect_duration......: avg=90.22ms  min=59ms   med=86ms   max=172ms   p(90)=119ms    p(95)=133ms
successful_redirects...: 1580 (3.27/s)
not_found_errors.......: 108 (0.22/s)
```

**HTTP Metrics**
```
http_req_duration......: avg=90.82ms  min=59.19ms  med=86.46ms  max=171.92ms  p(90)=118.75ms  p(95)=132.58ms
http_req_failed........: 0.00% (0 out of 1988)
http_reqs..............: 1988 (4.12/s)
```

**Execution Metrics**
```
iteration_duration.....: avg=2.59s   min=1.08s  med=2.55s  max=4.14s  p(90)=3.81s  p(95)=3.94s
iterations.............: 1978 (4.10/s)
vus....................: min=0  max=20
```

**Network Metrics**
```
data_received..........: 2.0 MB (4.2 kB/s)
data_sent..............: 192 kB (397 B/s)
```

#### Test Validation

All checks passed successfully:
```
checks_total.......: 3956 (8.19/s)
checks_succeeded...: 100.00% (3956 out of 3956)
checks_failed......: 0.00% (0 out of 3956)
```

**Successful Checks:**
- ✓ redirect: status is 302
- ✓ redirect: has location header
- ✓ create: status is 201
- ✓ create: has short code
- ✓ 404: status is 200 (not found page)
- ✓ 404: shows error message

### Key Observations

1. **Excellent baseline performance**: All requests completed under 200ms at p95
2. **Zero errors**: 100% success rate across all request types
3. **Consistent latency**: Low variance between average and median response times
4. **Predictable behavior**: System handles light load (5-20 users) without issues

---

## Heavy Load Test

*Results pending - test to be run next*

