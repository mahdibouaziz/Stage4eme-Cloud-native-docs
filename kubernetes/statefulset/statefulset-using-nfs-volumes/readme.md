# StatefulSets
Running Stateful workloads in the distributed cloud is generally considered harder than stateless ones. In classic three-tier applications, all the states would be stored in a database.

## What is Statefulset:
Kubernetes StatefulSet is a similar concept to a Deployment object – it also provides a way of managing and scaling a set of Pods, but it provides guarantees about the ordering and uniqueness (unique identity) of the Pods. In the same way as Deployment, it uses a Pod template to define what each replica should look like. You can scale it up and down and perform rollouts of new versions.

## VolumeClaimTemplates Attribute 
StatefulSet provides another type of template in its specification named `volumeClaimTemplates`. This template can be used for the dynamic creation of the `Persistent Volume Claim` of a given `Storage Class`. By doing this, the whole process of storage provisioning is fully dynamic – you just create a StatefulSet and the underlying storage objects are managed by the StatefulSet controller.

## Headless Service
You need to create a `headless Service` object that is responsible for managing the deterministic network identity (cluster DNS names) for Pods. The headless Service allows us to return all Pods IP addresses behind the service as DNS A records instead of a single DNS A record with a ClusterIP Service.

## StatefulSet with NFS Persistent Volume 
In this demo we will create a StatefulSet of PostgreSQL database with 3 replicas using NFS volumes.
### NFS  provisioner and storageClass:
Since the `volumeClaimTemplates` is used to create `Persistent Volumes Claims` using a `Storage Class` and `Provisioner` to Create a `Persistent Volumes`. But in Kubernetes, we don't find a built-in `Storage Class`. So we must create our own provisioner and storage class. This will be a hard task (Maybe i will try to make one!) because we need to deal with `RBAC`, etc ...

So we will Create a number of `Persistent Volumes` with the same `storageClassName` which make our demo more easy. You will understand on the demo !

### Static Persistent Volume Provision
#### 1- Create Persistent Volume
So Let's create some NFS Persistent Volumes!:
``` yaml
# Go to the Manifest folder if you want to see all the manifest (it's many Peristent Volumes)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-pv0
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 200Mi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: 192.168.1.80
    path: "/mnt/nfs-data/pv0"
---
apiVersion: v1
kind: PersistentVolume
metadata:
    name: pv-nfs-pv1
...
...
...
    nfs:
        server: 192.168.1.80
        path: "/mnt/nfs-data/pv2"
```
Create `/mnt/nfs-data/pv0`,`/mnt/nfs-data/pv1` and `/mnt/nfs-data/pv2` on the NFS server 
``` bash
justk8s@justk8s-nfs:/mnt/nfs-data$ mkdir pv{0,1,2}
justk8s@justk8s-nfs:/mnt/nfs-data$ ls
pv0 pv1 pv2
```
Create the Persistent Volumes using `kubectl apply ` command :
``` bash
justk8s@justk8s-master:~$ kubectl apply -f nfs-pv.yaml
persistentvolume "pv-nfs-pv0" created
persistentvolume "pv-nfs-pv1" created
persistentvolume "pv-nfs-pv2" created
```
Check the Persistent Volume Created:
``` bash
justk8s@justk8s-master:~$ kubectl get pv
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                  STORAGECLASS   REASON   AGE
pv-nfs-pv0   200Mi      RWO            Retain           Released    default/postgres-data-postgres-sts-0   manual                  1m
pv-nfs-pv1   200Mi      RWO            Retain           Available                                          manual                  1m
pv-nfs-pv2   200Mi      RWO            Retain           Available                                          manual                  1m
```
#### 2- Create a Configmap and Secret for the PostgreSQL database
So let's begin by Creating a configMap object:
``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-map
data:
  postgres-db: "database"
  postgres-user: "mohamed"
```
Create this configmap object
``` bash 
justk8s@justk8s-master:~$ kubectl apply -f first-configmap.yaml
configmap/config-map created
```
Now it's time for the Secret:
``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
type: Opaque
data:
  postgres-pass: "bW9oYW1lZA=="
```
Create the ConfigMaps Object:
``` bash
justk8s@justk8s-master:~$ kubectl apply -f first-secret.yaml
secret/database-secret created
```



#### 3- Create the StatefulSet
Now let's create a StatefulSet with ReplicaSet of PostgreSQL database
First we must Create a Headless Service, this is an example of headless service :
``` yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  labels:
    app: postgres-sts
spec:
  ports:
    - port: 5432
      name: postgres
      targetPort: 5432
  clusterIP: None
  selector:
    app: postgres-sts
```
Create the Headless Service Object to use it on the Statefulset manifest:
``` bash
justk8s@justk8s-master:~$ kubectl apply -f headless-svc.yaml
service/postgres-headless created
```
After creating the headless service, it's time to create our PostgreSQL StatefulSet:
``` yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-sts
spec:
    serviceName: "postgres-headless"
    replicas: 3
    selector:
        matchLabels:
            app: postgres-sts
    template:
        metadata:
            labels:
                app: postgres-sts
        spec:
            containers:
            - name: postgres
              image: postgres
              ports:
                - containerPort: 5432
              env:
                - name: POSTGRES_PASSWORD
                  valueFrom:
                    secretKeyRef:
                        name: database-secret
                        key: postgres-pass
                - name: POSTGRES_USER
                  valueFrom:
                    configMapKeyRef:
                        name: config-map
                        key: postgres-user
                - name: POSTGRES_DBNAME
                  valueFrom:
                    configMapKeyRef:
                        name: config-map
                        key: postgres-db
                - name: PGDATA
                  value: /var/lib/postgresql/data/pgdata
              volumeMounts:
              - name: postgres-data
                mountPath: /var/lib/postgresql/data/
    volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        storageClassName: manual
        accessModes: 
            - ReadWriteOnce
        resources:
            requests:
                storage: 200Mi
```
The volumeClaimTemplates section is used to trigger the Persistent Volumes that belong to the manual storageClass that we puted in the PV manifests!
Let's Now create the StatefulSet! 
``` bash
justk8s@justk8s-master:~$ kubectl apply -f postgress-sts.yaml
statefulset.apps/postgres-sts created
```
Don't forget to check if the StatefulSet work or not ! 
``` bash
justk8s@justk8s-master:~$ kubectl get pods
NAME               READY   STATUS   RESTARTS   AGE
postgres-sts-0   0/1     Error    0          8s
```
Wait! we have a problem here! There is an Error when creating the StatefulSet. Let's inspect the kubernetes pod logs and see what's going on !
``` bash
justk8s@justk8s-master:~$ kubectl logs postgresql-sts-0
chown: changing ownership of '/var/lib/postgresql/data/pgdata': Operation not permitted
```
Ah! The PostgreSQL container can't run the command chown on `/var/lib/postgresql/data/pgdata` (The mount point of the volume!). We can solve this problem either by create an init container with `alpine` image and run the chown command to the user with 999 uid (The default uid of PostgreSQL user) or by add the parameter `no_root_squash` on the NFS export!
I choose the easy one on this demo but creating the init container on cloud managed kubernetes can be a mandatory task such as in AKS (Azure Kubernetes Service)!

Change the NFS export in `/etc/exports` on NFS server like this:
``` bash
/mnt/nfs-data 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash) # add no_root_squash 
```
Apply the export changes:

``` bash
justk8s@justk8s-nfs:~$ sudo exportfs -a
justk8s@justk8s-nfs:~$ sudo systemctl restart nfs-kernel-server
```
Now Let's move to the master node again and check the StatefulSet, If the Error still apear delete the statefulset and create a now one!
``` bash
justk8s@justk8s-master:~$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
postgres-sts-0   1/1     Running   0          7s
postgres-sts-1   0/1     Pending   0          1s
```
Bingo! Everything is OK! Just you must know that the StatefulSet create the pods one after one and The Deployment create all the pods at the same time. So you can wait a few seconds and check the pods again !
``` bash
justk8s@justk8s-master:~$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
postgres-sts-0   1/1     Running   0          30s
postgres-sts-1   1/1     Running   0          21s
postgres-sts-2   1/1     Running   0          15s
```
You can also check the Persistent Volume Claims  created by the StatefulSet through the `volumeClaimTemplates` attribute by running `kubectl get pvc` command:
``` bash
justk8s@justk8s-master:~$  kubectl get pvc

NAME                           STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
postgres-data-postgres-sts-0   Bound    pv-nfs-pv1   200Mi      RWO            manual         2m
postgres-data-postgres-sts-1   Bound    pv-nfs-pv0   200Mi      RWO            manual         2m
postgres-data-postgres-sts-2   Bound    pv-nfs-pv2   200Mi      RWO            manual         2m
```
