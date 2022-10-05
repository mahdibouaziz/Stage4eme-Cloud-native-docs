# What is Prometheus?

- Prometheus was created to **monitor** highly dynamic container environments like Kubernetes, Docker Swarm, ….
- It can also be used in a traditional bare metal server non-container infrastructure.

# Where and Why is Prometheus used?

Prometheus is used to:

- **Constantly monitor** all the services.
- Send **alerts** when a service crash.
- **Identify problems before they even occur** and alert the system administrators.

Some use cases:

- Check regularly the status of the **memory usage** of the nodes.
- Check the **storage space** available on the node.

# Prometheus Architecture

The main component is the `Prometheus Server`, it does the actual monitoring work.

**Prometheus Server** is made of 3 parts:

- `Time Series Database`: stores all the **metrics** data (e.g current CPU usage, number of exceptions in an application, ….).
- `Data Retrieval Worker`: responsible for getting (**pulling**) these metrics from applications, services, servers, …. And storing them (pushing) into the Time Series Database.
- `HTTP Server`: accepts **PromQL** queries, used to display the data in a UI like **Prometheus Web UI** or **Grafana**, ….

![Alt text](./images/prom-archi.png?raw=true)

# Targets and Metrics:

- `Targets`: **what** does Prometheus monitor
  - Linux/ Windows Server
  - Apache Server
  - Single Application
  - Database
- `Metrics`: **which units** are monitored for those targets
  - CPU Status
  - Memory/Disk space usage
  - Exception Count
  - Request Count/Duration

Metrics are what gets saved in a Prometheus DB component

Metrics are saved in a Human-readable text-based format, and they have **TYPE** and **HELP** attributes.

We have 3 types:

- `Counter`: how many times does X happen?
- `Gauge`: what is the current value of X now?
- `Histogram`: How long or how big?

# How does Prometheus collect those metrics from targets?

Prometheus pulls metrics data from the target from the HTTP endpoint which by default is `hostaddress/metrics`

For that to work:

- The targets must expose the `/metrics` endpoint.
- Data must be in the **correct format** (that Prometheus understands).

# Targets endpoints and Exporters:

- Some services are by default exposing `/metrics` endpoints ⇒ you don’t need extra work to gather metrics from them.
- Many services don’t have native Prometheus endpoints ⇒ Extra component is required to do that. This component is called `Exporter`.

An `Exporter` is a script that fetches metrics from a target and converts them to the **correct format** that Prometheus understands and exposes this data at its own `/metrics` endpoint.

Prometheus has a lot of exporters and they are available as Docker images or libraries for specified languages.

# Alert Manager:

- This component is responsible for sending alerts via different channels (emails, slack, ….).
- Prometheus server will read the **alert rules** of the config file and if that rule is true an alert gets fired.

# Data Storage:

- Prometheus stores the metrics data on Disks (Local or Remote).
- Data is stored in a **Custom Time Series Format**, and because of that, you can’t write Prometheus data directly into a DB.

# PromQL Query Language:

- You can use PromQL to query the data directly or you can use more powerful visualization tools (like Grafana) that use under the hood of PromQL.

# Prometheus Characteristics:

Advantages:

- Reliable.
- Stand-alone and self-containing.
- Works even if other parts of the infrastructure are broken.
- No extensive setup is needed.

Disadvantages:

- Difficult to scale (horizontally).

# Prometheus Federation:

- If we need to scale Prometheus, we can build a **Prometheus Federation**.
- **Prometheus Federation** allows a Prometheus server to **scrape data from other Prometheus servers**.
