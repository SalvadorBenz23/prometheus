"use strict";
const express = require("express");
const prometheus_client = require("prom-client");

const port = 3000;
const app = express();

// Collect default metrics
prometheus_client.collectDefaultMetrics();

// Counter for the number of requests
const nb_of_requests_counter = new prometheus_client.Counter({
  name: "nb_of_requests",
  help: "Number of requests in our NodeJS app",
});

// Histogram for the duration of requests
const duration_of_requests_histogram = new prometheus_client.Histogram({
  name: "duration_of_requests",
  help: "Duration of requests in our NodeJS app",
  buckets: [0.1, 0.5, 1, 1.5, 2],
});

// Main endpoint
app.get("/", function (req, res) {
  const request_start = new Date();
  nb_of_requests_counter.inc();

  const waitingTime = Math.floor(Math.random() * 2000);
  setTimeout(() => {}, waitingTime);

  const request_stop = new Date();
  duration_of_requests_histogram.observe((request_stop - request_start) / 1000);

  res.send(`The request has taken ${waitingTime}ms.`);
});

// Metrics endpoint
app.get("/metrics", function (req, res) {
  res.set("Content-Type", prometheus_client.register.contentType);
  res.end(prometheus_client.register.metrics());
});

app.listen(port, () => console.log(`App running at http://localhost:${port}`));
