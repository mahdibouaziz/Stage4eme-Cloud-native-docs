# Alert Manager in Prometheus

When our Alert rules become in a `Firing` state, Prometheus send the Alert to the `Alertmanager`.

`Alertmanager` is its ouwn seperate application ==> it has its own configuration

`Alertmanager` needs to send an alert to an email, slack, .... (takes care of duplicating, grouping & routing them to the correct receiver).

Alertmanager has a basic UI, we can see it by exposing the `monitoring-kube-prometheus-alertmanager` service as a NodePort:

`kubectl patch svc monitoring-kube-prometheus-alertmanager -p '{"spec": {"type": "NodePort"}}' -n monitoring`

this is the UI:

![Alt text](./images/alertmanager-ui.png?raw=true)

# Configure Alert Manager

we have 3 main sections in the alert manager configuration:

- `global`: Defines global configuration for all the `receivers` and all the `routes`
- `route`: Which alerts should be send to which receivers
- `receivers`: These are the notification integration (where is alert managers sending the alerts)

We can create configuration for `Alertmanager` using the `Custom Kuberentes Components`

[https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/alertmanagerconfig-monitoring-coreos-com-v1alpha1.html]

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: main-rules-alert-config
  namespace: monitoring
spec:
  route:
    # global config for all routes
    receiver: "email"
    repeatInterval: 30m
    routes:
      #local config for each route
      - matchers:
          - name: alertname
            value: HostHighCpuLoad
      - matchers:
          - name: alertname
            value: KubernetesPodCrashLooping
          repeatInterval: 10m

  receivers:
    - name: "email"
      emailConfigs:
        - to: "test2@gmail.com"
          from: "test1@gmail.com"
          smarthost: "smtp.gmail.com:587"
          authUsername: "test1@gmail.com"
          authIdentity: "test1@gmail.com"
          authPassword: # this value is from a secret called gmail-auth (you must create it)
            name: gmail-auth
            key: password
```

then you just apply your secret that contains the email credetials:

`kubectl apply -f email-secret.yaml`

and apply the alert manager config

`kubectl apply -f alert-manager-config.yaml`

# Test Email Notification

we are going to trigger the High CPU load condition and see the alert gets fired ==> simulate a CPU load in the cluster.

This will similate a CPU test:

`kubectl run cpu-test --image=containerstack/cpustress -- --cpu 4 --timeout 60s --metrics-brief`

![Alt text](./images/alert-fired.png?raw=true)

NOTE: don't forget to delete the pod at the end:

`kubectl delete pod cpu-test`
