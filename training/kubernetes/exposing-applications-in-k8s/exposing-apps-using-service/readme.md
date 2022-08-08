## Pods are ephemeral

Pods have a lifecycle and can very easily die. When a worker node dies, the Pods running on the Node are also lost. when a Pod crashes or is deleted and another one comes up with the help of a ReplicaSet, the new Pod has a different IP address from the terminated one. This makes the Pod IP address unstable which can result in application errors. However, managing a connection to a Pod with a Service creates a stable IP address to reach the Pod at.

## The idea of a Service

A Service in Kubernetes is an abstraction which defines a logical set of Pods and a policy by which to access them. Each Pod has a unique internal IP address that cannot be exposed outside of the cluster without a Service. Services allow your applications to receive traffic. In other words, a Service is a permanent ip address that can be attached to each pod. The lifecycle of the Service and the Pod are not connected.

There are five types of Services:

- **ClusterIP (default)** - Exposes the Service on an internal IP in the cluster. This type makes the Service only reachable from within the cluster.
- **NodePort** - Exposes the Service on the same port of each selected Node in the cluster using NAT. Makes a Service accessible from outside the cluster using <NodeIP>:<NodePort>. Superset of ClusterIP.
- **LoadBalancer** - Creates an external load balancer in the current cloud (if supported) and assigns a fixed, external IP to the Service. Superset of NodePort.
- **ExternalName** - Maps the Service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value. No proxying of any kind is set up. This type requires v1.7 or higher of kube-dns, or CoreDNS version 0.0.8 or higher.
- **Headless** - Sometimes you don't need load-balancing and a single Service IP. In this case, you can create what are termed "headless" Services, by explicitly specifying "None" for the cluster IP (.spec.clusterIP).

## Creating a Service of type ClusterIP

#### Step 1: Create Deployment
Here is a manifest for a Deployment:

``` YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  selector:
    matchLabels:
      app: metrics
      department: sales
  replicas: 3
  template:
    metadata:
      labels:
        app: metrics
        department: sales
    spec:
      containers:
      - name: hello
        image: "us-docker.pkg.dev/google-samples/containers/gke/hello-app:2.0"
   ``` 
Copy the manifest to a file named my-deployment.yaml, and create the Deployment:

``` bash
kubectl apply -f my-deployment.yaml

```
Verify that three Pods are running:

```bash 
kubectl get pods
```
The output shows three running Pods:
```bash
NAME                            READY   STATUS    RESTARTS   AGE
my-deployment-dbd86c8c4-h5wsf   1/1     Running   0          7s
my-deployment-dbd86c8c4-qfw22   1/1     Running   0          7s
my-deployment-dbd86c8c4-wt4s6   1/1     Running   0          7s

```

#### Step 2 : Create YAML file
Here is a manifest for a Service of type ClusterIP:

``` YAML
apiVersion: v1
kind: Service
metadata:
  name: my-cip-service
spec:
  type: ClusterIP
  # Uncomment the below line to create a Headless Service
  # clusterIP: None
  selector:
    app: metrics
    department: sales
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```
The Service has a selector that specifies two labels:

- app: metrics
- department: sales
Each Pod in the Deployment that you created previously has those two labels. So the Pods in the Deployment will become members of this Service.

Copy the manifest to a file named my-cip-service.yaml, and create the Service:

``` bash
kubectl apply -f my-cip-service.yaml

```
Wait a moment for Kubernetes to assign a stable internal address to the Service, and then view the Service:
```bash 
kubectl get service my-cip-service --output yaml
```
The output shows a value for clusterIP:

```bash
spec:
  clusterIP: 10.59.241.241
``` 
#### Step 3 : Accessing your Service
List your running Pods:
``` bash
kubectl get pods

```
In the output, copy one of the Pod names that begins with my-deployment.

```bash
NAME                            READY   STATUS    RESTARTS   AGE
my-deployment-dbd86c8c4-h5wsf   1/1     Running   0          2m51s
```
Get a shell into one of your running containers:

```bash 
kubectl exec -it POD_NAME -- sh
```
Replace POD_NAME with the name of one of the Pods in my-deployment.

In your shell, install curl:

```bash
apk add --no-cache curl

```
In the container, make a request to your Service by using your cluster IP address and port 80. Notice that 80 is the value of the port field of your Service. This is the port that you use as a client of the Service.

``` bash
curl CLUSTER_IP:80
```
Replace CLUSTER_IP with the value of clusterIP in your Service.

Your request is forwarded to one of the member Pods on TCP port 8080, which is the value of the targetPort field. Note that each of the Service's member Pods must have a container listening on port 8080.

The response shows the output of hello-app:
```bash 
Hello, world!
Version: 2.0.0
Hostname: my-deployment-dbd86c8c4-h5wsf
```

*Kubernetes Official Documentation: [Using a Service to Expose Your App](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/)*

*Google Cloud Official Documentation: [EExposing applications using services ](https://cloud.google.com/kubernetes-engine/docs/how-to/exposing-apps)*

