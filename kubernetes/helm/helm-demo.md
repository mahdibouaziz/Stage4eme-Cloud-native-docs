# DEMO: Install a Stateful App on K8s using Helm

We Assume that we have 4 Ubuntu, The Kubernetes is installed and the `nfsserver1` host in the same network with the cluster :
| Role | Hostname | IP address |
| ---------- | ---------------- | --------------- |
| Master | kubemaster | 192.168.56.2/24 |
| Worker | kubenode01 | 192.168.56.3/24 |
| Worker | kubenode02 | 192.168.56.4/24 |
| NFS Server | nfsserver1 | 192.168.56.81/24 |

and you should have **Helm** installed

## Create a PV and a PVC

Create a PV:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-mongodb
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  nfs:
    server: 192.168.56.81 # the IP address of nfsserver host host
    path: "/mnt/nfs-data" # the location where to mount in the nfs server
```

`kubectl apply -f pv.yaml`

List the Persistent Volumes to make sure for the creation

`kubectl get pv`

Create a PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-mongodb
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 500Mi
```

`kubectl apply -f pvc.yaml`

List the Persistent Volume Claims to make sure for the creation

`kubectl get pvc`

## Deploy MongoDB StatefulSet

add the repository that contains MongoDB Helm Chart

`helm repo add bitnami https://charts.bitnami.com/bitnami`

The needed parameters in this chart:

- `architecture`
- `replicaCount`
- `persistence.existingClaim`
- `auth.rootPassword`

check the docs to see all the parameters: [https://github.com/bitnami/charts/tree/master/bitnami/mongodb]

This is the `values-mongodb.yaml` file:

```yaml
architecture: standalone
replicaCount: 1
persistence:
  existingClaim: "pvc-mongodb"
auth:
  rootPassword: secret-root-pwd
```

Now we just need to install our chart

`helm install mongodb -f values-mongodb.yaml bitnami/mongodb`
