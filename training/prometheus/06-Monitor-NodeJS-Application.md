# Monitor NodeJS Application our Own applcation

In this case, there is no `exporter` available, we need to define the `metrics` and create the exporter.

In order to monitor our own applications with Prometheus, we need to use `Prometheus Client Libraries` in those applications

## Prometheus Client Libraries:

- Abstract interface to expose your metrics that implement the Prometheus metric types.
- You need to choose a client library that matches the language in which your application is written.

# 1. `Expose metrics` for our Nodejs application using Nodejs client library

We are going to expose the :

- Number of requests
- Duration of requests

# 2. `Deploy` Nodejs app in the cluster

# 3. Configure Prometheus to scrape new target (`ServiceMonitor`)

# 4. `Visualize` scraped metrics in `Grafana` Dashboard.
