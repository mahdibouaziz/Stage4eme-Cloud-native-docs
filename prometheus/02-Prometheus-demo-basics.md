# Practical Prometheus-Demo

In this demo we will discuss and learn how to use Prometheus in practice

# Discussion: How to deploy the different Prometheus parts in Kubernetes Cluster?

## 1. Creating all configuration YAML files yourself

You need to create manifest files for each component of **Prometheus Statefulset**, **Alertmanager**, **Garfana**, all the **Configmaps** and **Secrets** that you need, etc ....

and then you need to execute them in the right order (because of the dependencies)

This option is **insufficient** and its a **lost of time and effort**

## 2. Using an Operator

Think of an operator is a manager of all Prometheus components that you create (manages the combination of all components as one unit)

we just need to **find a Prometheus operator** and then **deploy it in the K8s cluster**.

## 3. Using Helm chart to deploy Operator

This is the best option to set-up Prometheus.

`Helm` will do the **initial setup** and them the `Operator` will **manage the setup**

# Start the Demo

We Assume that we have 4 Ubuntu, The Kubernetes is installed and the `nfsserver1` host in the same network with the cluster :
| Role | Hostname | IP address |
| ---------- | ---------------- | --------------- |
| Master | kubemaster | 192.168.56.18/24 |
| Worker | kubenode01 | 192.168.56.19/24 |
| Worker | kubenode02 | 192.168.56.20/24 |

and you should have **Helm** installed

# Deploy a Microservice application to our cluster for testing purposes

We'are going to use a microservice application provided by google (for learning pusposes)

This is the repository: [https://github.com/mahdibouaziz/microservices-demo-google]

just clone it and run:

Don't forget to change the service `frontend-external` to NodePort

`kubectl apply -f ./release/kubernetes-manifests.yaml`

# Deploy Prometheus Stack using Helm

This is the Prometheus Helm repository: [https://github.com/prometheus-community/helm-charts]

add the repo as follows:

`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

update the repo

`helm repo update`

You can then run `helm search repo prometheus-community` to see the charts.

install Prometheus into its own namespace

`kubectl create namespace monitoring`

install the chart:

`helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring`

verify the deployment:

`kubectl get all -n monitoring`

![Alt text](./images/all-prometheus-stack.png?raw=true)

# Understanding Prometheus Stack Components

We have 2 **StatefulSet**:

- `prometheus-monitoring-kube-prometheus-prometheus` the Promethes Server itself, this is gonna be managed by the `Operator`
- `alertmanager-monitoring-kube-prometheus-alertmanager`

We have 3 **Deployements**:

- `monitoring-kube-state-metrics` : Created rometheus and Alertmanager StatefulSet
- `monitoring-kube-prometheus-operator` : its own Helm chart (dependency of this Helm chart) and it scrapes K8s components metrics (monitor the health of deployments, Statefulsets, Pods, .... inside the cluster)
- `monitoring-grafana`

We have 1 **DeamonSet** (runs on each node):

- `monitoring-prometheus-node-exporter`: Translates Worker Node metrics to Prometheus metrics

we have also pod, services, secrets, configmaps, ....

==> we have setup a **monitoring stack** + we get **by default** a **monitoring configuration for the K8s cluster** for our **Worker Nodes and K8s Components**

we have another interesting things that get created `CRD`

# Data Visualization

We want to notice when something **unexpected** happens, Observe any **anomalies**

- CPU spikes
- High Load
- Insufficient storage
- Unauthorized Requests

## Prometheus Web UI

We need to expose this service `monitoring-kube-prometheus-prometheus` to be able to see the Prometheus Web UI, to do that:

`kubectl patch svc monitoring-kube-prometheus-prometheus -p '{"spec": {"type": "NodePort"}}' -n monitoring`

and this is the UI:
![Alt text](./images/Prometheus%20Web%20UI.png?raw=true)

This is a simple UI, but it can be useful for getting some of the basic information about the cluster

To get the **targets** that Prometheus is monitoring: `Status` -> `Targets`

You need to add the **target**, which you want to monitor

You can check if the data you want to observe is available or not by searching it on the `Expression` on the main page of Prometheus

NOTES:

- **Instace** = an endpoint you can scrape
- **Job** = Collection of Instances with the same purpose.

## Grafana

Grafana is a Data Visualization tool that can access Prometheus metrics and gives us a nice visualization.

In the Prometheus Stack deployed, we already have Grafana deployed, we just need to expose the `monitoring-grafana` service to a NodePort.

`kubectl patch svc monitoring-grafana -p '{"spec": {"type": "NodePort"}}' -n monitoring`

Then you can access, The defualt credentials are:

- username: `admin `
- password: `prom-operator`

this is the UI:
![Alt text](./images/graphanaUI.png?raw=true)

An example of Dashboards:
![Alt text](./images/graphana%20dashboard%20example.png?raw=true)

### Grafana Dashboards:

- Dashboard is a set of one or more **panels**
- You can create your own Dashboards
- Organized into one or more rows
- **Row** is a logical divider within a dashboard
- **Rows** are used to group **panels** together
- **Panel** is the basic visualization building block in Grafana, composed by a query and a visualization.
- A panel can be moved and resized within a dashboard.

### Configure Users in Grafana

to configure users you just go to `Configuration` -> `Users`

# Create fake workloads to our application (to the frontend) - for testing purposes

let's create a pod that will do those requests for us:

`kubectl run curl-test --image=radial/busyboxplus:curl -i --tty --rm`

and inside the pod let's fake 200 requests:

`vi request.sh`

write this script:

```sh
for i in $(seq 1 200)
do
  curl [serviceName] > result.txt
done
```

Note: in our case the serviceName is `frontend`

make the script executable

`chmod +x request.sh`

and then execute it

`./request.sh`

finally go check your Grafana dashboards.
