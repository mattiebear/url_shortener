import http from "k6/http";
import { check, sleep } from "k6";
import { Counter, Trend } from "k6/metrics";

// Custom metrics
const createdLinks = new Counter("created_links");
const redirects = new Counter("successful_redirects");
const notFound = new Counter("not_found_errors");
const createDuration = new Trend("create_link_duration");
const redirectDuration = new Trend("redirect_duration");

// Test configuration
export const options = {
  stages: [
    { duration: "2m", target: 100 }, // Warm up
    { duration: "3m", target: 500 }, // Ramp to 500
    { duration: "3m", target: 1000 }, // Ramp to 1000
    { duration: "3m", target: 2000 }, // Ramp to 2000
    { duration: "3m", target: 5000 }, // Push to 5000
    { duration: "2m", target: 0 }, // Cool down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500", "p(99)<1000"], // 95% of requests under 500ms, 99% under 1s
    http_req_failed: ["rate<0.01"], // Less than 1% of requests should fail
    created_links: ["count>0"], // At least one link should be created
    successful_redirects: ["count>0"], // At least one redirect should succeed
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:4000";

// Array to store created short codes (shared across VUs)
const shortCodes = [];

export function setup() {
  console.log("Setting up test - creating initial short URLs...");

  // Create 20 URLs to use during the test
  for (let i = 0; i < 20; i++) {
    const url = `https://example.com/page-${i}?test=k6&iteration=${i}&timestamp=${Date.now()}`;
    const startTime = Date.now();

    const response = http.post(
      `${BASE_URL}/api/links`,
      JSON.stringify({ original_url: url }),
      {
        headers: { "Content-Type": "application/json" },
      },
    );

    const duration = Date.now() - startTime;
    createDuration.add(duration);

    if (response.status === 201) {
      // Parse JSON response to extract short code
      try {
        const body = JSON.parse(response.body);
        if (body.short_code) {
          shortCodes.push(body.short_code);
          createdLinks.add(1);
          console.log(`  ✓ Created short code: ${body.short_code}`);
        }
      } catch (e) {
        console.error(`Failed to parse response: ${e}`);
      }
    }

    sleep(0.1); // Small delay between creates
  }

  console.log(`Setup complete. Created ${shortCodes.length} short URLs.`);
  return { shortCodes };
}

export default function (data) {
  // Test scenario: Mix of creates and redirects
  const scenario = Math.random();

  if (scenario < 0.2) {
    // 20% of requests: Create new links
    createLink();
  } else if (scenario < 0.95) {
    // 75% of requests: Follow redirects
    followRedirect(data.shortCodes);
  } else {
    // 5% of requests: Test 404s (invalid short codes)
    test404();
  }

  sleep(Math.random() * 2); // Random sleep between 0-2 seconds
}

function createLink() {
  const url = `https://example.com/random/${Math.random().toString(36).substring(7)}?timestamp=${Date.now()}`;
  const startTime = Date.now();

  const response = http.post(
    `${BASE_URL}/api/links`,
    JSON.stringify({ original_url: url }),
    {
      headers: { "Content-Type": "application/json" },
      tags: { name: "CreateLink" },
    },
  );

  const duration = Date.now() - startTime;
  createDuration.add(duration);

  check(response, {
    "create: status is 201": (r) => r.status === 201,
    "create: has short code": (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.short_code !== undefined;
      } catch (e) {
        return false;
      }
    },
  });

  if (response.status === 201) {
    createdLinks.add(1);
  }
}

function followRedirect(shortCodes) {
  if (!shortCodes || shortCodes.length === 0) {
    return;
  }

  // Pick a random short code
  const shortCode = shortCodes[Math.floor(Math.random() * shortCodes.length)];
  const startTime = Date.now();

  const response = http.get(`${BASE_URL}/${shortCode}`, {
    redirects: 0, // Don't follow redirects automatically
    tags: { name: "Redirect" },
  });

  const duration = Date.now() - startTime;
  redirectDuration.add(duration);

  check(response, {
    "redirect: status is 302": (r) => r.status === 302,
    "redirect: has location header": (r) => r.headers["Location"] !== undefined,
  });

  if (response.status === 302) {
    redirects.add(1);
  }
}

function test404() {
  const invalidCode = `INVALID${Math.random().toString(36).substring(2, 8)}`;
  const response = http.get(`${BASE_URL}/${invalidCode}`, {
    tags: { name: "NotFound" },
  });

  check(response, {
    "404: status is 200 (not found page)": (r) => r.status === 200,
    "404: shows error message": (r) => r.body.includes("Link Not Found"),
  });

  if (response.body.includes("Link Not Found")) {
    notFound.add(1);
  }
}

export function teardown(data) {
  console.log("\n=================================");
  console.log("Load Test Complete!");
  console.log("=================================");
  console.log(`Total short codes created: ${shortCodes.length}`);
  console.log("\nCheck your Grafana dashboard at http://localhost:3000");
  console.log("Prometheus metrics at http://localhost:9090");
}
