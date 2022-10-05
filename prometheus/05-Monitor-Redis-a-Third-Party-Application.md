# Monitor Redis a Third Party Application

Until now, we have configured monitoring for our K8s Components and Resource Consumption on the Nodes.

We need also to monitor our Third-Party Application (Redis in our example) and our Own applcation (Online-google-shop).

The entire app (deployed in the [02 - Prometheus Demo Basics](./02-Prometheus-demo-basics.md)):
![Alt text](./images/application.png?raw=true)

To monitor Third-party application with Prometheus we need `Exporters` for the services.

# What are Exporters?

An `exporter` is an appication that connects to the service, gets metrics data from the service, **translates these metrics to a Prometheus understandable metrics**, and **expose** these translated metrics under `/metrics` endpoint .

When we deploy an Exporter in the cluster we need to tell Prometheus about this new Exporter. For that there is a Custom K8s Resource called `ServiceMonitor`.

# Deploy Redis Exporter

Redis exporter docs: [https://github.com/oliver006/redis_exporter]

## How we deploy the Redis Exporter in our cluster?

We are going to use Helm chart that has everthing configured for us.

Redis exporter Helm Chart: [https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-redis-exporter]

We need to customize the chart before using it:

create a `redis-values.yaml` that contains:

```yaml
serviceMonitor:
  enabled: true
  labels:
    release: monitoring # this is required to let Prometheus know the service

redisAddress: redis://[redis-service-name]:6379 #change this to your servicename (in our case `redis://redis-cart:6379`)
```

then install the chart with the customized values

`helm install redis-exporter prometheus-community/prometheus-redis-exporter -f redis-values.yaml`

list the pods to verify the exporter:

`kubectl get pods`

verify the ServiceMonitor

`kubectl get servicemonitor`

and you can see in the Prometheus UI a new target is added called `redis-exporter`

![Alt text](./images/redis-exporter.png?raw=true)

and that means that Prometheus now has `redis application metrics` you can see them in the UI

![Alt text](./images/redis-metrics.png?raw=true)

# Alerting rules for Redis

We want to get notified when Redis app is down.

We want to observe whether our Redis application has too many connections at once.

let's create a file called `redis-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: redis-rules
  #these labels are required to Prometheus operator to be able to triger the rules
  labels:
    app: kube-prometheus-stack
    release: monitoring
spec:
  groups:
    - name: redis.rules
      rules:
        - alert: RedisDown
          expr: redis_up == 0
          for: 0m
          labels:
            severity: critical
          annotations:
            summary: Redis down (instance {{ $labels.instance }})
            description: "Redis instance is down\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

        - alert: RedisTooManyConnections
          expr: redis_connected_clients > 100
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: Redis too many connections (instance {{ $labels.instance }})
            description: "Redis instance has too many connections\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```

Note: there is a documentation where you can find ready alert rules for a lot of different services: [https://awesome-prometheus-alerts.grep.to/]

now let's go and apply these rules:

`kubectl apply -f redis-rules.yaml`

# Trigger the RedisDown rule

to similate this event, we need to sscale down the redis deployment to 0

`kubectl edit deployment redis-cart` --> and change the replicas to 0

Note: don't forget to turn the replicas back to 1

# Create Redis Dashboard in Grafana

We could create Grafana Dashboard with Redis metrics ourselves or use existing Redis Dashboard.

You can find some dashboard on Grafana website: [https://grafana.com/grafana/dashboards/]

in our example we will use this dashboard: [https://grafana.com/grafana/dashboards/11835]

to import this dashboard:

1. Copy the Dashboard id from the website
2. go to Grafana dashboard (in your cluster)
3. Click import
   ![Alt text](./images/grafana-import.png?raw=true)
