# Kubectl Commands
## Create
Create a resource from a file or from stdin:

`kubectl create -f FILENAME`

Create a deployment with the specified name:

`kubectl create deployment NAME --image=image -- [COMMAND] [args...]`


**Create a pod using the data in pod.json:**

`kubectl create -f ./pod.json`

**Create a deployment named my-dep that runs the budybox image and exposes the port 5701:**


`kubectl create deployment my-dep --image=busybox --port=5701`

## Get
List all pods in ps format:

`kubectl get pods`

## Run
Create and run a particular image in a pod:

`kubectl run NAME --image=image [--env="key=value"] [--port=port] [--dry-run=server|client] [--overrides=inline-json] [--command] -- [COMMAND] [args...]`

**Start a hazelcast pod and let the container expose port 5701:**

`kubectl run hazelcast --image=hazelcast/hazelcast --port=5701`

## Expose
Expose a resource as a new Kubernetes service:

`kubectl expose (-f FILENAME | TYPE NAME) [--port=port] [--protocol=TCP|UDP|SCTP] [--target-port=number-or-name] [--name=name] [--external-ip=external-ip-of-service] [--type=type]`

**Create a service for a replicated nginx, which serves on port 80 and connects to the containers on port 8000:**

`kubectl expose rc nginx --port=80 --target-port=8000`

## Delete
Delete resources by file names, stdin, resources and names, or by resources and label selector:

`kubectl delete ([-f FILENAME] | [-k DIRECTORY] | TYPE [(NAME | -l label | --all)])`

**Delete a pod using the type and name specified in pod.json:**

`kubectl delete -f ./pod.json`

*Kubernetes Documentation: [Kubernetes Commands - Getting Started](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#create)*
