# Alert Rules in Prometheus

Now we have Dashboards in Grafana that show the anomalies and let us visualize the data that we are interested in.

But in reality, people won't wait in front of the screen for anomalies.

When something happens in the cluster you need to get notified by email, slack, ... then you will check the Grafana Dashboards and analyse and fix the issue.

In this tutorial we will learn how to `Configure our monitoring stack to notify us whenever something unexpected happens`.

Alerting with Prometheus is separated into 2 parts:

1.  Define what we want to be notified about (`Alert Rules`)
2.  Send notification (`Alertmanager`)

# Take a look at Existing Alert Rules (deployed by default)

Go to the Prometheus UI and click on `Alerts`, this will list all of the alerts already configured alerts grouped by the name of the alert.

![Alt text](./images/alerts.png?raw=true)

Green alert == this alert is inactive or condition not met

Red alert = Firing or Condition is met

## Configuration Syntax of an Alert Rule

An alert has a:

- `name`: descriptive name about the alert.
- `expr`: the logical **expression** (the condition) defined in a `PromQL` syntax.
- `for`: defines the duration that Prometheus need to wait before sending an alert (maybe the Problem solves itself). For example in the Picture, Prometheus will check that the alert continues to be active for 10 minutes before firing the alert.
- `labels.severity`: contains a value like `critical`, `warning`, that defines the priority of the problem.
- `annotations`: specifies a set of descriptive information (additional information) that is gonna be sent if the alert is triggered.

an alert rule example:
![Alt text](./images/alert-rule.png?raw=true)

# Create our own `Alert Rules`

## Create an alert rule when the CPU usage > 50%

```yaml
name: HostHighCpuLoad
expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 50
for: 2m
labels:
  severity: warning
  namespace: monitoring
annotations:
  description: "CPU load on host is over 50% \n  The Value = {{ $value }} \n Instance = {{ $labels.instance }} \n"
  summary: "Host CPU load high"
```

let's discuss about the expression:

- we have a metric: `node_cpu_seconds_total`
- this metric has a lot of modes (`iowait`, `system`, `idle`, ...)
- we've selected the mode `idle` and that means that the CPU is _not being used_
- and then we get the rate (avearge utilization) per second over a period of 2 minutes `rate( ..... [2m])`
- finnaly because we want to measure the CPU usage per host we added `avg by (instance)`

## add our alert rules to Prometheus

We have Prometheus running in K8s cluster as `Prometheus Operator`.

Prometheus Operator extends the K8s API and let us create `Custom Kuberentes Components` defined by `CRDs`.

[https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/prometheusrule-monitoring-coreos-com-v1.html]

==> to add this alert rule to Prometheus, we just need to create the manifest file with the custom `apiVersion` and `kind` and just apply it.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: main-rules
  namespace: monitoring
  #these labels are required to Prometheus operator to be able to triger the rules
  labels:
    app: kube-prometheus-stack
    release: monitoring
spec:
  groups:
    - name: main.rules
      rules:
        - alert: HostHighCpuLoad
          expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 50
          for: 2m
          labels:
            severity: warning
            namespace: monitoring
          annotations:
            description: "CPU load on host is over 50% \n  The Value = {{ $value }} \n Instance = {{ $labels.instance }} \n"
            summary: "Host CPU load high"

        # A group is an array of rules ==> let's create a second alert rule when the Pod cannot start:
        - alert: KubernetesPodCrashLooping
          expr: kube_pod_container_status_restarts_total > 5
          for: 0m
          labels:
            severity: critical
            namespace: monitoring
          annotations:
            description: "Pod {{ $labels.pod }} is crash looping \n  The Value = {{ $value }}"
            summary: "Kubernetes Pod crash looping"
```

now we just need to apply our manifest file:

`kubectl apply -f custom-alert-rules.yaml`

`kubectl get PrometheusRule -n monitoring`

![Alt text](./images/custom-rule.png?raw=true)

Finally, we are able to see these rules in the Prometheus UI:

![Alt text](./images/custom-rule-ui.png?raw=true)

# Test our custom `Alert Rules`

we are going to trigger the High CPU load condition and see the alert gets fired ==> simulate a CPU load in the cluster.

This will similate a CPU test:

`kubectl run cpu-test --image=containerstack/cpustress -- --cpu 4 --timeout 30s --metrics-brief`

![Alt text](./images/alert-pending.png?raw=true)

NOTE: don't forget to delete the pod at the end:

`kubectl delete pod cpu-test`
