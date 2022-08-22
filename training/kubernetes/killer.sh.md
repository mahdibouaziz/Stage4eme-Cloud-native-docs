# CKA Simulator Kubernetes 1.24
### Pre Setup
Once you've gained access to your terminal it might be wise to spend ~1 minute to setup your environment. You could set these:

``` bash
alias k=kubectl                         # will already be pre-configured

export do="--dry-run=client -o yaml"    # k create deploy nginx --image=nginx $do

export now="--force --grace-period 0"   # k delete pod x $now
```

### Vim
The following settings will already be configured in your real exam environment in ~/.vimrc. But it can never hurt to be able to type these down:

``` bash 
set tabstop=2
set expandtab
set shiftwidth=2
```
## Question 1 | Contexts

Task weight: 1%

 

You have access to multiple clusters from your main terminal through kubectl contexts. Write all those context names into `/opt/course/1/contexts.`

Next write a command to display the current context into `/opt/course/1/context_default_kubectl.sh`, the command should use kubectl.

Finally write a second command doing the same thing into `/opt/course/1/context_default_no_kubectl.sh`, but without the use of `kubectl`.

#### Answer:
Maybe the fastest way is just to run:

``` bash
k config get-contexts # copy manually

k config get-contexts -o name > /opt/course/1/contexts
```

Or using jsonpath:
``` bash
k config view -o yaml # overview
k config view -o jsonpath="{.contexts[*].name}"
k config view -o jsonpath="{.contexts[*].name}" | tr " " "\n" # new lines
k config view -o jsonpath="{.contexts[*].name}" | tr " " "\n" > /opt/course/1/contexts 
```
The content should then look like:

``` text
# /opt/course/1/contexts
k8s-c1-H
k8s-c2-AC
k8s-c3-CCC
```

Next create the first command:
``` text
# /opt/course/1/context_default_kubectl.sh
kubectl config current-context
```

``` bash
➜ sh /opt/course/1/context_default_kubectl.sh
k8s-c1-H
```

In the real exam you might need to filter and find information from bigger lists of resources, hence knowing a little jsonpath and simple bash filtering will be helpful.

The second command could also be improved to:
``` text
# /opt/course/1/context_default_no_kubectl.sh
cat ~/.kube/config | grep current | sed -e "s/current-context: //"
```

## Question 2 | Schedule Pod on Master Node
Task weight: 3%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Create a single Pod of image `httpd:2.4.41-alpine` in Namespace `default`. The Pod should be named `pod1` and the container should be named `pod1-container`. This Pod should only be scheduled on a `master node`, do not add new labels any nodes.

 

### Answer:
First we find the master node(s) and their taints:
``` bash
k get node # find master node

k describe node cluster1-master1 | grep Taint -A1 # get master node taints

k get node cluster1-master1 --show-labels # get master node labels
```

>NOTE: In K8s 1.24 master/controlplane nodes have two Taints which means we have to add Tolerations for both. This is done during transitioning from the wording "master" to "controlplane".

 

Next we create the Pod template:
``` bash
# check the export on the very top of this document so we can use $do
k run pod1 --image=httpd:2.4.41-alpine $do > 2.yaml

vim 2.yaml
```
Perform the necessary changes manually. Use the Kubernetes docs and search for example for tolerations and nodeSelector to find examples:
``` yaml
# 2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: httpd:2.4.41-alpine
    name: pod1-container                       # change
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:                                 # add
  - effect: NoSchedule                         # add
    key: node-role.kubernetes.io/master        # add
  - effect: NoSchedule                         # add
    key: node-role.kubernetes.io/control-plane # add
  nodeSelector:                                # add
    node-role.kubernetes.io/control-plane: ""  # add
status: {}
```

Important here to add the toleration for running on master nodes, but also the nodeSelector to make sure it only runs on master nodes. If we only specify a toleration the Pod can be scheduled on master or worker nodes.

Now we create it:
``` bash
k -f 2.yaml create
```
Let's check if the pod is scheduled:
``` bash
➜ k get pod pod1 -o wide
NAME   READY   STATUS    RESTARTS   ...    NODE               NOMINATED NODE
pod1   1/1     Running   0          ...    cluster1-master1   <none>  
```    

## Question 3 | Scale down StatefulSet
Task weight: 1%

 

Use context: `kubectl config use-context k8s-c1-H`

 

There are two Pods named `o3db-*` in Namespace `project-c13`. C13 management asked you to scale the Pods down to one replica to save resources.

 

#### Answer:
If we check the Pods we see two replicas:
``` bash
➜ k -n project-c13 get pod | grep o3db
o3db-0                                  1/1     Running   0          52s
o3db-1                                  1/1     Running   0          42s
```
From their name it looks like these are managed by a StatefulSet. But if we're not sure we could also check for the most common resources which manage Pods:
``` bash
➜ k -n project-c13 get deploy,ds,sts | grep o3db
statefulset.apps/o3db   2/2     2m56s
```
Confirmed, we have to work with a StatefulSet. To find this out we could also look at the Pod labels:
``` bash
➜ k -n project-c13 get pod --show-labels | grep o3db
o3db-0                                  1/1     Running   0          3m29s   app=nginx,controller-revision-hash=o3db-5fbd4bb9cc,statefulset.kubernetes.io/pod-name=o3db-0
o3db-1                                  1/1     Running   0          3m19s   app=nginx,controller-revision-hash=o3db-5fbd4bb9cc,statefulset.kubernetes.io/pod-name=o3db-1
```
To fulfil the task we simply run:

``` bash
➜ k -n project-c13 scale sts o3db --replicas 1
statefulset.apps/o3db scaled

➜ k -n project-c13 get sts o3db
NAME   READY   AGE
o3db   1/1     4m39s
C13 Mangement is happy again.
```


### Question 4 | Pod Ready if Service is reachable
Task weight: 4%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Do the following in Namespace `default`. Create a single Pod named `ready-if-service-ready` of image `nginx:1.16.1-alpine`. Configure a LivenessProbe which simply runs `true`. Also configure a ReadinessProbe which does check if the url `http://service-am-i-ready:80` is reachable, you can use `wget -T2 -O- http://service-am-i-ready:80` for this. Start the Pod and confirm it isn't ready because of the ReadinessProbe.

Create a second Pod named `am-i-ready` of image `nginx:1.16.1-alpine` with label `id: cross-server-ready`. The already existing Service `service-am-i-ready` should now have that second Pod as endpoint.

Now the first Pod should be in ready state, confirm that.

 

#### Answer:
It's a bit of an anti-pattern for one Pod to check another Pod for being ready using probes, hence the normally available readinessProbe.httpGet doesn't work for absolute remote urls. Still the workaround requested in this task should show how probes and `Pod<->Service` communication works.

First we create the first Pod:
``` bash
k run ready-if-service-ready --image=nginx:1.16.1-alpine $do > 4_pod1.yaml
vim 4_pod1.yaml
```
Next perform the necessary additions manually:
``` yaml
# 4_pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: ready-if-service-ready
  name: ready-if-service-ready
spec:
  containers:
  - image: nginx:1.16.1-alpine
    name: ready-if-service-ready
    resources: {}
    livenessProbe:                               # add from here
      exec:
        command:
        - 'true'
    readinessProbe:
      exec:
        command:
        - sh
        - -c
        - 'wget -T2 -O- http://service-am-i-ready:80'   # to here
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Then create the Pod:

``` bash
k -f 4_pod1.yaml create
And confirm its in a non-ready state:

➜ k get pod ready-if-service-ready
NAME                     READY   STATUS    RESTARTS   AGE
ready-if-service-ready   0/1     Running   0          7s
We can also check the reason for this using describe:

➜ k describe pod ready-if-service-ready
 ...
  Warning  Unhealthy  18s   kubelet, cluster1-worker1  Readiness probe failed: Connecting to service-am-i-ready:80 (10.109.194.234:80)
wget: download timed out
```
Now we create the second Pod:
``` bash
k run am-i-ready --image=nginx:1.16.1-alpine --labels="id=cross-server-ready"
The already existing Service service-am-i-ready should now have an Endpoint:

k describe svc service-am-i-ready
k get ep # also possible
```
Which will result in our first Pod being ready, just give it a minute for the Readiness probe to check again:
``` bash
➜ k get pod ready-if-service-ready
NAME                     READY   STATUS    RESTARTS   AGE
ready-if-service-ready   1/1     Running   0          53s
```
Look at these Pods coworking together!


## Question 5 | Kubectl sorting
Task weight: 1%

 

Use context: `kubectl config use-context k8s-c1-H`

 

There are various Pods in all namespaces. Write a command into `/opt/course/5/find_pods.sh` which lists all Pods sorted by their AGE (`metadata.creationTimestamp`).

Write a second command into `/opt/course/5/find_pods_uid.sh` which lists all Pods sorted by field `metadata.uid`. Use kubectl sorting for both commands.

 

#### Answer:
A good resources here (and for many other things) is the kubectl-cheat-sheet. You can reach it fast when searching for "cheat sheet" in the Kubernetes docs.
``` text
# /opt/course/5/find_pods.sh
kubectl get pod -A --sort-by=.metadata.creationTimestamp
```
And to execute:
``` bash
➜ sh /opt/course/5/find_pods.sh
NAMESPACE         NAME                                       ...          AGE
kube-system       kube-scheduler-cluster1-master1            ...          63m
kube-system       etcd-cluster1-master1                      ...          63m
kube-system       kube-apiserver-cluster1-master1            ...          63m
kube-system       kube-controller-manager-cluster1-master1   ...          63m
...
```
For the second command:
``` text
# /opt/course/5/find_pods_uid.sh
kubectl get pod -A --sort-by=.metadata.uid
```
And to execute:
``` bash
➜ sh /opt/course/5/find_pods_uid.sh
NAMESPACE         NAME                                      ...          AGE
kube-system       coredns-5644d7b6d9-vwm7g                  ...          68m
project-c13       c13-3cc-runner-heavy-5486d76dd4-ddvlt     ...          63m
project-hamster   web-hamster-shop-849966f479-278vp         ...          63m
project-c13       c13-3cc-web-646b6c8756-qsg4b              ...          63m
```

## Question 6 | Storage, PV, PVC, Pod volume
Task weight: 8%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Create a new PersistentVolume named `safari-pv`. It should have a capacity of 2Gi, accessMode ReadWriteOnce, hostPath `/Volumes/Data` and no storageClassName defined.

Next create a new PersistentVolumeClaim in Namespace `project-tiger` named `safari-pvc` . It should request 2Gi storage, accessMode ReadWriteOnce and should not define a storageClassName. The PVC should bound to the PV correctly.

Finally create a new Deployment `safari` in Namespace `project-tiger` which mounts that volume at `/tmp/safari-data.` The Pods of that Deployment should be of image `httpd:2.4.41-alpine`.

 

#### Answer
``` bash
vim 6_pv.yaml
```
Find an example from https://kubernetes.io/docs and alter it:
``` yaml
# 6_pv.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
 name: safari-pv
spec:
 capacity:
  storage: 2Gi
 accessModes:
  - ReadWriteOnce
 hostPath:
  path: "/Volumes/Data"
```
Then create it:
``` bash
k -f 6_pv.yaml create
```
Next the PersistentVolumeClaim:

vim 6_pvc.yaml
Find an example from https://kubernetes.io/docs and alter it:
``` yaml
# 6_pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: safari-pvc
  namespace: project-tiger
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
     storage: 2Gi
```
Then create:
``` bash
k -f 6_pvc.yaml create
```
And check that both have the status Bound:
``` bash
➜ k -n project-tiger get pv,pvc
NAME                         CAPACITY  ... STATUS   CLAIM                    ...
persistentvolume/safari-pv   2Gi       ... Bound    project-tiger/safari-pvc ...

NAME                               STATUS   VOLUME      CAPACITY ...
persistentvolumeclaim/safari-pvc   Bound    safari-pv   2Gi      ...
```
Next we create a Deployment and mount that volume:
``` bash
k -n project-tiger create deploy safari \
  --image=httpd:2.4.41-alpine $do > 6_dep.yaml
```
vim 6_dep.yaml
Alter the yaml to mount the volume:
``` yaml
# 6_dep.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: safari
  name: safari
  namespace: project-tiger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: safari
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: safari
    spec:
      volumes:                                      # add
      - name: data                                  # add
        persistentVolumeClaim:                      # add
          claimName: safari-pvc                     # add
      containers:
      - image: httpd:2.4.41-alpine
        name: container
        volumeMounts:                               # add
        - name: data                                # add
          mountPath: /tmp/safari-data               # add
```
``` bash
k -f 6_dep.yaml create
```
We can confirm its mounting correctly:
``` bash
➜ k -n project-tiger describe pod safari-5cbf46d6d-mjhsb  | grep -A2 Mounts:   
    Mounts:
      /tmp/safari-data from data (rw) # there it is
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-n2sjj (ro)
```


## Question 7 | Node and Pod Resource Usage
Task weight: 1%

 

Use context: kubectl `config use-context k8s-c1-H`

 

The metrics-server has been installed in the cluster. Your college would like to know the kubectl commands to:

* show Nodes resource usage
* show Pods and their containers resource usage
Please write the commands into `/opt/course/7/node.sh` and `/opt/course/7/pod.sh`.

 

Answer:
The command we need to use here is top:
``` bash
➜ k top -h
Display Resource (CPU/Memory/Storage) usage.

 The top command allows you to see the resource consumption for nodes or pods.

 This command requires Metrics Server to be correctly configured and working on the server.

Available Commands:
  node        Display Resource (CPU/Memory/Storage) usage of nodes
  pod         Display Resource (CPU/Memory/Storage) usage of pods
```
We see that the metrics server provides information about resource usage:
``` bash
➜ k top node
NAME               CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
cluster1-master1   178m         8%     1091Mi          57%       
cluster1-worker1   66m          6%     834Mi           44%       
cluster1-worker2   91m          9%     791Mi           41% 
```
We create the first file:
``` text
# /opt/course/7/node.sh
kubectl top node
```
For the second file we might need to check the docs again:
``` bash
➜ k top pod -h
Display Resource (CPU/Memory/Storage) usage of pods.
...
Namespace in current context is ignored even if specified with --namespace.
      --containers=false: If present, print usage of containers within a pod.
      --no-headers=false: If present, print output without headers.
...
```
With this we can finish this task:
``` text
# /opt/course/7/pod.sh
kubectl top pod --containers=true
```

## Question 8 | Get Master Information
Task weight: 2%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Ssh into the master node with `ssh cluster1-master1`. Check how the master components `kubelet`, `kube-apiserver`, `kube-scheduler`, `kube-controller-manager` and `etcd` are started/installed on the master node. Also find out the name of the DNS application and how it's started/installed on the master node.

Write your findings into file `/opt/course/8/master-components.txt`. The file should be structured like:
``` text
# /opt/course/8/master-components.txt
kubelet: [TYPE]
kube-apiserver: [TYPE]
kube-scheduler: [TYPE]
kube-controller-manager: [TYPE]
etcd: [TYPE]
dns: [TYPE] [NAME]
```
Choices of `[TYPE]` are: `not-installed`, `process`, `static-pod`, `pod`

 

#### Answer:
We could start by finding processes of the requested components, especially the kubelet at first:
``` bash
➜ ssh cluster1-master1

root@cluster1-master1:~# ps aux | grep kubelet # shows kubelet process
We can see which components are controlled via systemd looking at /etc/systemd/system directory:

➜ root@cluster1-master1:~# find /etc/systemd/system/ | grep kube
/etc/systemd/system/kubelet.service.d
/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
/etc/systemd/system/multi-user.target.wants/kubelet.service

➜ root@cluster1-master1:~# find /etc/systemd/system/ | grep etcd
```
This shows kubelet is controlled via systemd, but no other service named kube nor etcd. It seems that this cluster has been setup using kubeadm, so we check in the default manifests directory:
``` bash
➜ root@cluster1-master1:~# find /etc/kubernetes/manifests/
/etc/kubernetes/manifests/
/etc/kubernetes/manifests/kube-controller-manager.yaml
/etc/kubernetes/manifests/etcd.yaml
/etc/kubernetes/manifests/kube-apiserver.yaml
/etc/kubernetes/manifests/kube-scheduler.yaml
(The kubelet could also have a different manifests directory specified via parameter --pod-manifest-path in it's systemd startup config)
```
This means the main 4 master services are setup as static Pods. Actually, let's check all Pods running on in the kube-system Namespace on the master node:
``` bash
➜ root@cluster1-master1:~# kubectl -n kube-system get pod -o wide | grep master1
coredns-5644d7b6d9-c4f68                   1/1     Running            ...   cluster1-master1
coredns-5644d7b6d9-t84sc                   1/1     Running            ...   cluster1-master1
etcd-cluster1-master1                      1/1     Running            ...   cluster1-master1
kube-apiserver-cluster1-master1            1/1     Running            ...   cluster1-master1
kube-controller-manager-cluster1-master1   1/1     Running            ...   cluster1-master1
kube-proxy-q955p                           1/1     Running            ...   cluster1-master1
kube-scheduler-cluster1-master1            1/1     Running            ...   cluster1-master1
weave-net-mwj47                            2/2     Running            ...   cluster1-master1
```
There we see the 5 static pods, with -cluster1-master1 as suffix.

We also see that the dns application seems to be coredns, but how is it controlled?
``` bash
➜ root@cluster1-master1$ kubectl -n kube-system get ds
NAME         DESIRED   CURRENT   ...   NODE SELECTOR            AGE
kube-proxy   3         3         ...   kubernetes.io/os=linux   155m
weave-net    3         3         ...   <none>                   155m

➜ root@cluster1-master1$ kubectl -n kube-system get deploy
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   2/2     2            2           155m
```
Seems like coredns is controlled via a Deployment. We combine our findings in the requested file:
``` text
# /opt/course/8/master-components.txt
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coredns
```
You should be comfortable investigating a running cluster, know different methods on how a cluster and its services can be setup and be able to troubleshoot and find error sources.

 


## Question 9 | Kill Scheduler, Manual Scheduling
Task weight: 5%

 

Use context: `kubectl config use-context k8s-c2-AC`

 

Ssh into the master node with `ssh cluster2-master1`. Temporarily stop the `kube-scheduler`, this means in a way that you can start it again afterwards.

Create a single Pod named `manual-schedule `of image `httpd:2.4-alpine`, confirm its created but not scheduled on any node.

Now you're the scheduler and have all its power, manually schedule that Pod on node `cluster2-master1`. Make sure it's running.

Start the `kube-scheduler` again and confirm its running correctly by creating a second Pod named `manual-schedule2` of image `httpd:2.4-alpine` and check if it's running on `cluster2-worker1`.

 

#### Answer:
Stop the Scheduler
First we find the master node:
``` bash
➜ k get node
NAME               STATUS   ROLES    AGE   VERSION
cluster2-master1   Ready    master   26h   v1.24.1
cluster2-worker1   Ready    <none>   26h   v1.24.1
```
Then we connect and check if the scheduler is running:
``` bash
➜ ssh cluster2-master1

➜ root@cluster2-master1:~$ kubectl -n kube-system get pod | grep schedule
kube-scheduler-cluster2-master1            1/1     Running   0          6s
```
Kill the Scheduler (temporarily):
``` bash
➜ root@cluster2-master1:~$ cd /etc/kubernetes/manifests/

➜ root@cluster2-master1:~$ mv kube-scheduler.yaml ..
```
And it should be stopped:
``` bash
➜ root@cluster2-master1:~$ kubectl -n kube-system get pod | grep schedule

➜ root@cluster2-master1:~# 
```

##### Create a Pod
Now we create the Pod:
``` bash
k run manual-schedule --image=httpd:2.4-alpine
```
And confirm it has no node assigned:
``` bash
➜ k get pod manual-schedule -o wide
NAME              READY   STATUS    ...   NODE     NOMINATED NODE
manual-schedule   0/1     Pending   ...   <none>   <none>        
```

Manually schedule the Pod
Let's play the scheduler now:
``` bash
k get pod manual-schedule -o yaml > 9.yaml
```
``` yaml
# 9.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2020-09-04T15:51:02Z"
  labels:
    run: manual-schedule
  managedFields:
...
    manager: kubectl-run
    operation: Update
    time: "2020-09-04T15:51:02Z"
  name: manual-schedule
  namespace: default
  resourceVersion: "3515"
  selfLink: /api/v1/namespaces/default/pods/manual-schedule
  uid: 8e9d2532-4779-4e63-b5af-feb82c74a935
spec:
  nodeName: cluster2-master1        # add the master node name
  containers:
  - image: httpd:2.4-alpine
    imagePullPolicy: IfNotPresent
    name: manual-schedule
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-nxnc7
      readOnly: true
  dnsPolicy: ClusterFirst
...
```
The only thing a scheduler does, is that it sets the `nodeName` for a Pod declaration. How it finds the correct node to schedule on, that's a very much complicated matter and takes many variables into account.

As we cannot kubectl apply or kubectl edit , in this case we need to delete and create or replace:
``` bash
k -f 9.yaml replace --force
```
How does it look?
``` bash
➜ k get pod manual-schedule -o wide
NAME              READY   STATUS    ...   NODE            
manual-schedule   1/1     Running   ...   cluster2-master1
```
It looks like our Pod is running on the master now as requested, although no tolerations were specified. Only the scheduler takes tains/tolerations/affinity into account when finding the correct node name. That's why its still possible to assign Pods manually directly to a master node and skip the scheduler.

 

Start the scheduler again
``` bash
➜ ssh cluster2-master1

➜ root@cluster2-master1:~$ cd /etc/kubernetes/manifests/

➜ root@cluster2-master1:~$ mv ../kube-scheduler.yaml .
```
Checks its running:
``` bash
➜ root@cluster2-master1:~# kubectl -n kube-system get pod | grep schedule
kube-scheduler-cluster2-master1            1/1     Running   0          16s
```
Schedule a second test Pod:
``` bash
k run manual-schedule2 --image=httpd:2.4-alpine
➜ k get pod -o wide | grep schedule
manual-schedule    1/1     Running   ...   cluster2-master1
manual-schedule2   1/1     Running   ...   cluster2-worker1
```
Back to normal.


## Question 10 | RBAC ServiceAccount Role RoleBinding
Task weight: 6%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Create a new ServiceAccount `processor` in Namespace `project-hamster`. Create a Role and RoleBinding, both named `processor` as well. These should allow the new SA to only create `Secrets` and `ConfigMaps` in that Namespace.

 

### Answer:
Let's talk a little about `RBAC `resources
A ClusterRole|Role defines a set of permissions and where it is available, in the whole cluster or just a single Namespace.

A `ClusterRoleBinding`|`RoleBinding` connects a set of permissions with an account and defines where it is applied, in the whole cluster or just a single Namespace.

Because of this there are 4 different `RBAC` combinations and 3 valid ones:

`Role` + `RoleBinding` (available in single Namespace, applied in single Namespace)
`ClusterRole` + `ClusterRoleBinding `(available cluster-wide, applied cluster-wide)
`ClusterRole` + `RoleBinding` (available cluster-wide, applied in single Namespace)
`Role` + `ClusterRoleBinding` (NOT POSSIBLE: available in single Namespace, applied cluster-wide)

To the solution
We first create the ServiceAccount:
``` bash
➜ k -n project-hamster create sa processor
serviceaccount/processor created
```
Then for the Role:
``` bash
k -n project-hamster create role -h # examples
```
So we execute:
``` bash
k -n project-hamster create role processor \
  --verb=create \
  --resource=secret \
  --resource=configmap
```
Which will create a Role like:
``` bash
 kubectl -n project-hamster create role accessor --verb=create --resource=secret --resource=configmap
```
``` yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: processor
  namespace: project-hamster
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  - configmaps
  verbs:
  - create
```
Now we bind the Role to the ServiceAccount:
``` bash
k -n project-hamster create rolebinding -h # examples
```
So we create it:
``` bash
k -n project-hamster create rolebinding processor \
  --role processor \
  --serviceaccount project-hamster:processor
```
This will create a RoleBinding like:
``` bash
kubectl -n project-hamster create rolebinding processor --role processor --serviceaccount project-hamster:processor
```
``` yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: processor
  namespace: project-hamster
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: processor
subjects:
- kind: ServiceAccount
  name: processor
  namespace: project-hamster
```
To test our RBAC setup we can use kubectl auth can-i:
``` bash
k auth can-i -h # examples
```
Like this:
``` bash
➜ k -n project-hamster auth can-i create secret \
  --as system:serviceaccount:project-hamster:processor
yes

➜ k -n project-hamster auth can-i create configmap \
  --as system:serviceaccount:project-hamster:processor
yes

➜ k -n project-hamster auth can-i create pod \
  --as system:serviceaccount:project-hamster:processor
no

➜ k -n project-hamster auth can-i delete secret \
  --as system:serviceaccount:project-hamster:processor
no

➜ k -n project-hamster auth can-i get configmap \
  --as system:serviceaccount:project-hamster:processor
no
```
Done.

## Question 11 | DaemonSet on all Nodes
Task weight: 4%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Use Namespace `project-tiger` for the following. Create a DaemonSet named `ds-important` with image `httpd:2.4-alpine` and labels `id=ds-important` and `uuid=18426a0b-5f59-4e10-923f-c0e078e82462`. The Pods it creates should request 10 millicore cpu and 10 mebibyte memory. The Pods of that DaemonSet should run on all nodes, master and worker.

 

#### Answer:
As of now we aren't able to create a DaemonSet directly using kubectl, so we create a Deployment and just change it up:
``` bash
k -n project-tiger create deployment --image=httpd:2.4-alpine ds-important $do > 11.yaml

vim 11.yaml
```
(Sure you could also search for a DaemonSet example yaml in the Kubernetes docs and alter it.)

 

> NOTE: In K8s 1.24 master/controlplane nodes have two Taints which means we have to add Tolerations for both. This is done during transitioning from the wording "master" to "controlplane".

 

Then we adjust the yaml to:
``` yaml
# 11.yaml
apiVersion: apps/v1
kind: DaemonSet                                     # change from Deployment to Daemonset
metadata:
  creationTimestamp: null
  labels:                                           # add
    id: ds-important                                # add
    uuid: 18426a0b-5f59-4e10-923f-c0e078e82462      # add
  name: ds-important
  namespace: project-tiger                          # important
spec:
  #replicas: 1                                      # remove
  selector:
    matchLabels:
      id: ds-important                              # add
      uuid: 18426a0b-5f59-4e10-923f-c0e078e82462    # add
  #strategy: {}                                     # remove
  template:
    metadata:
      creationTimestamp: null
      labels:
        id: ds-important                            # add
        uuid: 18426a0b-5f59-4e10-923f-c0e078e82462  # add
    spec:
      containers:
      - image: httpd:2.4-alpine
        name: ds-important
        resources:
          requests:                                 # add
            cpu: 10m                                # add
            memory: 10Mi                            # add
      tolerations:                                  # add
      - effect: NoSchedule                          # add
        key: node-role.kubernetes.io/master         # add
      - effect: NoSchedule                          # add
        key: node-role.kubernetes.io/control-plane  # add
#status: {}                                         # remove
```
It was requested that the DaemonSet runs on all nodes, so we need to specify the toleration for this.

Let's confirm:
``` bash
k -f 11.yaml create
➜ k -n project-tiger get ds
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
ds-important   3         3         3       3            3           <none>          8s
```
``` bash
➜ k -n project-tiger get pod -l id=ds-important -o wide
NAME                      READY   STATUS          NODE
ds-important-6pvgm        1/1     Running   ...   cluster1-worker1
ds-important-lh5ts        1/1     Running   ...   cluster1-master1
ds-important-qhjcq        1/1     Running   ...   cluster1-worker2
```

## Question 12 | Deployment on all Nodes
Task weight: 6%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Use Namespace `project-tiger` for the following. Create a Deployment named `deploy-important` with label `id=very-important` (the Pods should also have this label) and 3 replicas. It should contain two containers, the first named `container1` with image `nginx:1.17.6-alpine` and the second one named `container2` with image `kubernetes/pause`.

There should be only ever one Pod of that Deployment running on one worker node. We have two worker nodes: cluster1-worker1 and cluster1-worker2. Because the Deployment has three replicas the result should be that on both nodes one Pod is running. The third Pod won't be scheduled, unless a new worker node will be added.

In a way we kind of simulate the behaviour of a DaemonSet here, but using a Deployment and a fixed number of replicas.

 

Answer:
There are two possible ways, one using podAntiAffinity and one using topologySpreadConstraint.

 

PodAntiAffinity
The idea here is that we create a "Inter-pod anti-affinity" which allows us to say a Pod should only be scheduled on a node where another Pod of a specific label (here the same label) is not already running.

Let's begin by creating the Deployment template:
``` bash
k -n project-tiger create deployment \
  --image=nginx:1.17.6-alpine deploy-important $do > 12.yaml
```
```bash
vim 12.yaml
```
Then change the yaml to:
``` yaml
# 12.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    id: very-important                  # change
  name: deploy-important
  namespace: project-tiger              # important
spec:
  replicas: 3                           # change
  selector:
    matchLabels:
      id: very-important                # change
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        id: very-important              # change
    spec:
      containers:
      - image: nginx:1.17.6-alpine
        name: container1                # change
        resources: {}
      - image: kubernetes/pause         # add
        name: container2                # add
      affinity:                                             # add
        podAntiAffinity:                                    # add
          requiredDuringSchedulingIgnoredDuringExecution:   # add
          - labelSelector:                                  # add
              matchExpressions:                             # add
              - key: id                                     # add
                operator: In                                # add
                values:                                     # add
                - very-important                            # add
            topologyKey: kubernetes.io/hostname             # add
status: {}
```
Specify a topologyKey, which is a pre-populated Kubernetes label, you can find this by describing a node.

 

TopologySpreadConstraints
We can achieve the same with topologySpreadConstraints. Best to try out and play with both.
``` yaml
# 12.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    id: very-important                  # change
  name: deploy-important
  namespace: project-tiger              # important
spec:
  replicas: 3                           # change
  selector:
    matchLabels:
      id: very-important                # change
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        id: very-important              # change
    spec:
      containers:
      - image: nginx:1.17.6-alpine
        name: container1                # change
        resources: {}
      - image: kubernetes/pause         # add
        name: container2                # add
      topologySpreadConstraints:                 # add
      - maxSkew: 1                               # add
        topologyKey: kubernetes.io/hostname      # add
        whenUnsatisfiable: DoNotSchedule         # add
        labelSelector:                           # add
          matchLabels:                           # add
            id: very-important                   # add
status: {}
```

Apply and Run
Let's run it:

``` bash
k -f 12.yaml create
```

Then we check the Deployment status where it shows 2/3 ready count:
``` bash
➜ k -n project-tiger get deploy -l id=very-important
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
deploy-important   2/3     3            2           2m35s
```
And running the following we see one Pod on each worker node and one not scheduled.

``` bash
➜ k -n project-tiger get pod -o wide -l id=very-important
NAME                                READY   STATUS    ...   NODE             
deploy-important-58db9db6fc-9ljpw   2/2     Running   ...   cluster1-worker1
deploy-important-58db9db6fc-lnxdb   0/2     Pending   ...   <none>          
deploy-important-58db9db6fc-p2rz8   2/2     Running   ...   cluster1-worker2
```
If we kubectl describe the Pod `deploy-important-58db9db6fc-lnxdb` it will show us the reason for not scheduling is our implemented `podAntiAffinity` ruling:
``` text
Warning  FailedScheduling  63s (x3 over 65s)  default-scheduler  0/3 nodes are available: 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 2 node(s) didn't match pod affinity/anti-affinity, 2 node(s) didn't satisfy existing pods anti-affinity rules.
```
Or our topologySpreadConstraints:
``` text
Warning  FailedScheduling  16s   default-scheduler  0/3 nodes are available: 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 2 node(s) didn't match pod topology spread constraints.
```
## Question 13 | Multi Containers and Pod shared Volume
Task weight: 4%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Create a Pod named `multi-container-playground` in Namespace `default` with three containers, named `c1`, `c2` and `c3`. There should be a volume attached to that Pod and mounted into every container, but the volume shouldn't be persisted or shared with other Pods.

Container c1 should be of image `nginx:1.17.6-alpine` and have the name of the node where its Pod is running available as environment variable `MY_NODE_NAME`.

Container c2 should be of image `busybox:1.31.1` and write the output of the date command every second in the shared volume into file date.log. You can use `while true; do date >> /your/vol/path/date.log; sleep 1; done` for this.

Container c3 should be of image `busybox:1.31.1` and constantly send the content of file date.log from the shared volume to stdout. You can use `tail -f /your/vol/path/date.log for this`.

Check the logs of container c3 to confirm correct setup.

 

#### Answer:
First we create the Pod template:
``` bash
k run multi-container-playground --image=nginx:1.17.6-alpine $do > 13.yaml
```
``` bash
vim 13.yaml
```
And add the other containers and the commands they should execute:
``` yaml
# 13.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: multi-container-playground
  name: multi-container-playground
spec:
  containers:
  - image: nginx:1.17.6-alpine
    name: c1                                                                      # change
    resources: {}
    env:                                                                          # add
    - name: MY_NODE_NAME                                                          # add
      valueFrom:                                                                  # add
        fieldRef:                                                                 # add
          fieldPath: spec.nodeName                                                # add
    volumeMounts:                                                                 # add
    - name: vol                                                                   # add
      mountPath: /vol                                                             # add
  - image: busybox:1.31.1                                                         # add
    name: c2                                                                      # add
    command: ["sh", "-c", "while true; do date >> /vol/date.log; sleep 1; done"]  # add
    volumeMounts:                                                                 # add
    - name: vol                                                                   # add
      mountPath: /vol                                                             # add
  - image: busybox:1.31.1                                                         # add
    name: c3                                                                      # add
    command: ["sh", "-c", "tail -f /vol/date.log"]                                # add
    volumeMounts:                                                                 # add
    - name: vol                                                                   # add
      mountPath: /vol                                                             # add
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:                                                                        # add
    - name: vol                                                                   # add
      emptyDir: {}                                                                # add
status: {}
```
``` bash
k -f 13.yaml create
```
Oh boy, lot's of requested things. We check if everything is good with the Pod:
``` bash
➜ k get pod multi-container-playground
NAME                         READY   STATUS    RESTARTS   AGE
multi-container-playground   3/3     Running   0          95s
```
Good, then we check if container c1 has the requested node name as env variable:
``` bash
➜ k exec multi-container-playground -c c1 -- env | grep MY
MY_NODE_NAME=cluster1-worker2
```
And finally we check the logging:
``` bash
➜ k logs multi-container-playground -c c3
Sat Dec  7 16:05:10 UTC 2077
Sat Dec  7 16:05:11 UTC 2077
Sat Dec  7 16:05:12 UTC 2077
Sat Dec  7 16:05:13 UTC 2077
Sat Dec  7 16:05:14 UTC 2077
Sat Dec  7 16:05:15 UTC 2077
Sat Dec  7 16:05:16 UTC 2077
```

## Question 14 | Find out Cluster Information
Task weight: 2%

 

Use context: `kubectl config use-context k8s-c1-H`

 

You're ask to find out following information about the cluster `k8s-c1-H`:

* How many master nodes are available?
* How many worker nodes are available?
* What is the Service CIDR?
* Which Networking (or CNI Plugin) is configured and where is its config file?
* Which suffix will static pods have that run on cluster1-worker1?
* Write your answers into file /opt/course/14/cluster-info, structured like this:
``` text
# /opt/course/14/cluster-info
1: [ANSWER]
2: [ANSWER]
3: [ANSWER]
4: [ANSWER]
5: [ANSWER]
```
 

#### Answer:
How many master and worker nodes are available?
``` bash
➜ k get node
NAME               STATUS   ROLES    AGE   VERSION
cluster1-master1   Ready    master   27h   v1.24.1
cluster1-worker1   Ready    <none>   27h   v1.24.1
cluster1-worker2   Ready    <none>   27h   v1.24.1
```
We see one master and two workers.

 

What is the Service CIDR?
``` bash
➜ ssh cluster1-master1

➜ root@cluster1-master1:~# cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep range
    - --service-cluster-ip-range=10.96.0.0/12
```

Which Networking (or CNI Plugin) is configured and where is its config file?

``` bash
➜ root@cluster1-master1:~# find /etc/cni/net.d/
/etc/cni/net.d/
/etc/cni/net.d/10-weave.conflist

➜ root@cluster1-master1:~# cat /etc/cni/net.d/10-weave.conflist
{
    "cniVersion": "0.3.0",
    "name": "weave",
...
```

By default the kubelet looks into `/etc/cni/net.d` to discover the CNI plugins. This will be the same on every master and worker nodes.

 

Which suffix will static pods have that run on `cluster1-worker1`?
The suffix is the node hostname with a leading hyphen. It used to be -static in earlier Kubernetes versions.

 

##### Result
The resulting /opt/course/14/cluster-info could look like:
``` text
# /opt/course/14/cluster-info

# How many master nodes are available?
1: 1

# How many worker nodes are available?
2: 2

# What is the Service CIDR?
3: 10.96.0.0/12

# Which Networking (or CNI Plugin) is configured and where is its config file?
4: Weave, /etc/cni/net.d/10-weave.conflist

# Which suffix will static pods have that run on cluster1-worker1?
5: -cluster1-worker1
```


## Question 15 | Cluster Event Logging
Task weight: 3%

 

Use context: `kubectl config use-context k8s-c2-AC`

 

Write a command into `/opt/course/15/cluster_events.sh` which shows the latest events in the whole cluster, ordered by time. Use `kubectl` for it.

Now kill the `kube-proxy` Pod running on node `cluster2-worker1` and write the events this caused into `/opt/course/15/pod_kill.log`.

Finally kill the containerd container of the `kube-proxy` Pod on node `cluster2-worker1` and write the events into `/opt/course/15/container_kill.log`.

Do you notice differences in the events both actions caused?

 

#### Answer:
``` text
# /opt/course/15/cluster_events.sh
kubectl get events -A --sort-by=.metadata.creationTimestamp
```
Now we kill the kube-proxy Pod:

``` bash
k -n kube-system get pod -o wide | grep proxy # find pod running on cluster2-worker1

k -n kube-system delete pod kube-proxy-z64cg
```
Now check the events:
``` text
sh /opt/course/15/cluster_events.sh
```
Write the events the killing caused into `/opt/course/15/pod_kill.log`:
``` text
# /opt/course/15/pod_kill.log
kube-system   9s          Normal    Killing           pod/kube-proxy-jsv7t   ...
kube-system   3s          Normal    SuccessfulCreate  daemonset/kube-proxy   ...
kube-system   <unknown>   Normal    Scheduled         pod/kube-proxy-m52sx   ...
default       2s          Normal    Starting          node/cluster2-worker1  ...
kube-system   2s          Normal    Created           pod/kube-proxy-m52sx   ...
kube-system   2s          Normal    Pulled            pod/kube-proxy-m52sx   ...
kube-system   2s          Normal    Started           pod/kube-proxy-m52sx   ...
```

Finally we will try to provoke events by killing the container belonging to the container of the kube-proxy Pod:

``` bash
➜ ssh cluster2-worker1

➜ root@cluster2-worker1:~$ crictl ps | grep kube-proxy
1e020b43c4423   36c4ebbc9d979   About an hour ago   Running   kube-proxy     ...

➜ root@cluster2-worker1:~$ crictl rm 1e020b43c4423
1e020b43c4423

➜ root@cluster2-worker1:~$ crictl ps | grep kube-proxy
0ae4245707910   36c4ebbc9d979   17 seconds ago      Running   kube-proxy     ...    
``` 
We killed the main container `(1e020b43c4423)`, but also noticed that a new container `(0ae4245707910)` was directly created. Thanks Kubernetes!

Now we see if this caused events again and we write those into the second file:
``` bash
sh /opt/course/15/cluster_events.sh
```
```text
# /opt/course/15/container_kill.log
kube-system   13s         Normal    Created      pod/kube-proxy-m52sx    ...
kube-system   13s         Normal    Pulled       pod/kube-proxy-m52sx    ...
kube-system   13s         Normal    Started      pod/kube-proxy-m52sx    ...
```
Comparing the events we see that when we deleted the whole Pod there were more things to be done, hence more events. For example was the DaemonSet in the game to re-create the missing Pod. Where when we manually killed the main container of the Pod, the Pod would still exist but only its container needed to be re-created, hence less events.

## Question 16 | Namespaces and Api Resources
Task weight: 2%

 

Use context: `kubectl config use-context k8s-c1-H`

 

Create a new Namespace called `cka-master`.

Write the names of all namespaced Kubernetes resources (like Pod, Secret, ConfigMap...) into `/opt/course/16/resources.txt`.

Find the `project-*` Namespace with the highest number of Roles defined in it and write its name and amount of Roles into `/opt/course/16/crowded-namespace.txt`.

 

Answer:
Namespace and Namespaces Resources
We create a new Namespace:
``` bash
k create ns cka-master
```
Now we can get a list of all resources like:
``` bash
k api-resources    # shows all

k api-resources -h # help always good

k api-resources --namespaced -o name > /opt/course/16/resources.txt
```
Which results in the file:
``` text
# /opt/course/16/resources.txt
bindings
configmaps
endpoints
events
limitranges
persistentvolumeclaims
pods
podtemplates
replicationcontrollers
resourcequotas
secrets
serviceaccounts
services
controllerrevisions.apps
daemonsets.apps
deployments.apps
replicasets.apps
statefulsets.apps
localsubjectaccessreviews.authorization.k8s.io
horizontalpodautoscalers.autoscaling
cronjobs.batch
jobs.batch
leases.coordination.k8s.io
events.events.k8s.io
ingresses.extensions
ingresses.networking.k8s.io
networkpolicies.networking.k8s.io
poddisruptionbudgets.policy
rolebindings.rbac.authorization.k8s.io
roles.rbac.authorization.k8s.io
```

Namespace with most Roles
``` bash
➜ k -n project-c13 get role --no-headers | wc -l
No resources found in project-c13 namespace.
0

➜ k -n project-c14 get role --no-headers | wc -l
300

➜ k -n project-hamster get role --no-headers | wc -l
No resources found in project-hamster namespace.
0

➜ k -n project-snake get role --no-headers | wc -l
No resources found in project-snake namespace.
0

➜ k -n project-tiger get role --no-headers | wc -l
No resources found in project-tiger namespace.
0
```
Finally we write the name and amount into the file:
``` text
# /opt/course/16/crowded-namespace.txt
project-c14 with 300 resources
```
## Question 17 | Find Container of Pod and check info
Task weight: 3%

 

Use context: kubectl config use-context k8s-c1-H

 

In Namespace project-tiger create a Pod named tigers-reunite of image httpd:2.4.41-alpine with labels pod=container and container=pod. Find out on which node the Pod is scheduled. Ssh into that node and find the containerd container belonging to that Pod.

Using command crictl:

Write the ID of the container and the info.runtimeType into /opt/course/17/pod-container.txt
Write the logs of the container into /opt/course/17/pod-container.log
 

Answer:
First we create the Pod:
``` bash
k -n project-tiger run tigers-reunite \
  --image=httpd:2.4.41-alpine \
  --labels "pod=container,container=pod"
```
Next we find out the node it's scheduled on:

``` bash
k -n project-tiger get pod -o wide

# or fancy:
k -n project-tiger get pod tigers-reunite -o jsonpath="{.spec.nodeName}"
```
Then we ssh into that node and and check the container info:

``` bash

➜ ssh cluster1-worker2

➜ root@cluster1-worker2:~# crictl ps | grep tigers-reunite
b01edbe6f89ed    54b0995a63052    5 seconds ago    Running        tigers-reunite ...

➜ root@cluster1-worker2:~# crictl inspect b01edbe6f89ed | grep runtimeType
    "runtimeType": "io.containerd.runc.v2",
```
Then we fill the requested file (on the main terminal):
``` text
# /opt/course/17/pod-container.txt
b01edbe6f89ed io.containerd.runc.v2
```
Finally we write the container logs in the second file:
``` bash
ssh cluster1-worker2 'crictl logs b01edbe6f89ed' &> /opt/course/17/pod-container.log
```
The `&>` in above's command redirects both the standard output and standard error.

You could also simply run crictl logs on the node and copy the content manually, if its not a lot. The file should look like:
``` text
# /opt/course/17/pod-container.log
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.44.0.37. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.44.0.37. Set the 'ServerName' directive globally to suppress this message
[Mon Sep 13 13:32:18.555280 2021] [mpm_event:notice] [pid 1:tid 139929534545224] AH00489: Apache/2.4.41 (Unix) configured -- resuming normal operations
[Mon Sep 13 13:32:18.555610 2021] [core:notice] [pid 1:tid 139929534545224] AH00094: Command line: 'httpd -D FOREGROUND'
```

 

## Question 18 | Fix Kubelet
Task weight: 8%

 

Use context: `kubectl config use-context k8s-c3-CCC`

 

There seems to be an issue with the kubelet not running on `cluster3-worker1`. Fix it and confirm that cluster has node `cluster3-worker1` available in Ready state afterwards. You should be able to schedule a Pod on `cluster3-worker1 `afterwards.

Write the reason of the issue into `/opt/course/18/reason.txt`.

 

Answer:
The procedure on tasks like these should be to check if the kubelet is running, if not start it, then check its logs and correct errors if there are some.

Always helpful to check if other clusters already have some of the components defined and running, so you can copy and use existing config files. Though in this case it might not need to be necessary.

Check node status:
``` bash
➜ k get node
NAME               STATUS     ROLES    AGE   VERSION
cluster3-master1   Ready      master   27h   v1.23.1
cluster3-worker1   NotReady   <none>   26h   v1.23.1
```
First we check if the kubelet is running:
``` bash
➜ ssh cluster3-worker1

➜ root@cluster3-worker1:~$ ps aux | grep kubelet
root     29294  0.0  0.2  14856  1016 pts/0    S+   11:30   0:00 grep --color=auto kubelet
```
Nope, so we check if its configured using systemd as service:
``` text
➜ root@cluster3-worker1:~$ service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: inactive (dead) since Sun 2019-12-08 11:30:06 UTC; 50min 52s ago
...
```
Yes, its configured as a service with config at /etc/systemd/system/kubelet.service.d/10-kubeadm.conf, but we see its inactive. Let's try to start it:
``` bash
➜ root@cluster3-worker1:~$ service kubelet start

➜ root@cluster3-worker1:~$ service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: activating (auto-restart) (Result: exit-code) since Thu 2020-04-30 22:03:10 UTC; 3s ago
     Docs: https://kubernetes.io/docs/home/
  Process: 5989 ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=203/EXEC)
 Main PID: 5989 (code=exited, status=203/EXEC)

Apr 30 22:03:10 cluster3-worker1 systemd[5989]: kubelet.service: Failed at step EXEC spawning /usr/local/bin/kubelet: No such file or directory
Apr 30 22:03:10 cluster3-worker1 systemd[1]: kubelet.service: Main process exited, code=exited, status=203/EXEC
Apr 30 22:03:10 cluster3-worker1 systemd[1]: kubelet.service: Failed with result 'exit-code'.
```
We see its trying to execute /usr/local/bin/kubelet with some parameters defined in its service config file. A good way to find errors and get more logs is to run the command manually (usually also with its parameters).
``` bash
➜ root@cluster3-worker1:~$ /usr/local/bin/kubelet
-bash: /usr/local/bin/kubelet: No such file or directory

➜ root@cluster3-worker1:~$ whereis kubelet
kubelet: /usr/bin/kubelet
```
Another way would be to see the extended logging of a service like using journalctl -u kubelet.

Well, there we have it, wrong path specified. Correct the path in file /etc/systemd/system/kubelet.service.d/10-kubeadm.conf and run:
``` bash
vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf $ fix

systemctl daemon-reload && systemctl restart kubelet

systemctl status kubelet  $ should now show running
```
Also the node should be available for the api server, give it a bit of time though:
``` bash
➜ k get node
NAME               STATUS   ROLES    AGE   VERSION
cluster3-master1   Ready    master   27h   v1.23.1
cluster3-worker1   Ready    <none>   27h   v1.23.1
```
Finally we write the reason into the file:
``` text
# /opt/course/18/reason.txt
wrong path to kubelet binary specified in service config
```

 

## Question 19 | Create Secret and mount into Pod
Task weight: 3%

 

> NOTE: This task can only be solved if questions 18 or 20 have been successfully implemented and the `k8s-c3-CCC` cluster has a functioning worker node

 

Use context: `kubectl config use-context k8s-c3-CCC`

 

Do the following in a new Namespace `secret`. Create a Pod named `secret-pod` of image `busybox:1.31.1` which should keep running for some time.

There is an existing Secret located at `/opt/course/19/secret1.yaml`, create it in the Namespace `secret` and mount it readonly into the Pod at `/tmp/secret1`.

Create a new Secret in Namespace `secret` called `secret2` which should contain `user=user1` and `pass=1234`. These entries should be available inside the Pod's container as environment variables `APP_USER` and `APP_PASS`.

Confirm everything is working.

 

#### Answer
First we create the Namespace and the requested Secrets in it:
``` bash
k create ns secret

cp /opt/course/19/secret1.yaml 19_secret1.yaml

vim 19_secret1.yaml
```
We need to adjust the Namespace for that Secret:
``` yaml
# 19_secret1.yaml
apiVersion: v1
data:
  halt: IyEgL2Jpbi9zaAo...
kind: Secret
metadata:
  creationTimestamp: null
  name: secret1
  namespace: secret           # change
```

``` bash
k -f 19_secret1.yaml create
```
Next we create the second Secret:
``` bash
k -n secret create secret generic secret2 --from-literal=user=user1 --from-literal=pass=1234
```

Now we create the Pod template:
``` bash
k -n secret run secret-pod --image=busybox:1.31.1 $do -- sh -c "sleep 5d" > 19.yaml

vim 19.yaml
```
Then make the necessary changes:
``` yaml
# 19.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: secret-pod
  name: secret-pod
  namespace: secret                       # add
spec:
  containers:
  - args:
    - sh
    - -c
    - sleep 1d
    image: busybox:1.31.1
    name: secret-pod
    resources: {}
    env:                                  # add
    - name: APP_USER                      # add
      valueFrom:                          # add
        secretKeyRef:                     # add
          name: secret2                   # add
          key: user                       # add
    - name: APP_PASS                      # add
      valueFrom:                          # add
        secretKeyRef:                     # add
          name: secret2                   # add
          key: pass                       # add
    volumeMounts:                         # add
    - name: secret1                       # add
      mountPath: /tmp/secret1             # add
      readOnly: true                      # add
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:                                # add
  - name: secret1                         # add
    secret:                               # add
      secretName: secret1                 # add
status: {}
```
It might not be necessary in current K8s versions to specify the readOnly: true because it's the default setting anyways.

And execute:
``` bash
k -f 19.yaml create
```
Finally we check if all is correct:
``` bash
➜ k -n secret exec secret-pod -- env | grep APP
APP_PASS=1234
APP_USER=user1
➜ k -n secret exec secret-pod -- find /tmp/secret1
/tmp/secret1
/tmp/secret1/..data
/tmp/secret1/halt
/tmp/secret1/..2019_12_08_12_15_39.463036797
/tmp/secret1/..2019_12_08_12_15_39.463036797/halt
➜ k -n secret exec secret-pod -- cat /tmp/secret1/halt
#! /bin/sh
### BEGIN INIT INFO
# Provides:          halt
# Required-Start:
# Required-Stop:
# Default-Start:
# Default-Stop:      0
# Short-Description: Execute the halt command.
# Description:
...
```
All is good.

 

 

## Question 20 | Update Kubernetes Version and join cluster
Task weight: 10%

 

Use context: `kubectl config use-context k8s-c3-CCC`

 

Your coworker said node `cluster3-worker2` is running an older Kubernetes version and is not even part of the cluster. Update Kubernetes on that node to the exact version that's running on `cluster3-master1`. Then add this node to the cluster. Use `kubeadm` for this.

 

#### Answer:
Upgrade Kubernetes to cluster3-master1 version
Search in the docs for kubeadm upgrade: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade

``` bash
➜ k get node
NAME               STATUS     ROLES           AGE   VERSION
cluster3-master1   Ready      control-plane   23d   v1.24.1
cluster3-worker1   NotReady   <none>          23d   v1.24.1
```
Master node seems to be running Kubernetes 1.24.1 and cluster3-worker2 is not yet part of the cluster.
``` bash

➜ ssh cluster3-worker2

➜ root@cluster3-worker2:~$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.1", GitCommit:"3ddd0f45aa91e2f30c70734b175631bec5b5825a", GitTreeState:"clean", BuildDate:"2022-05-24T12:24:38Z", GoVersion:"go1.18.2", Compiler:"gc", Platform:"linux/amd64"}

➜ root@cluster3-worker2:~$ kubectl version
Client Version: version.Info{Major:"1", Minor:"23", GitVersion:"v1.23.1", GitCommit:"86ec240af8cbd1b60bcc4c03c20da9b98005b92e", GitTreeState:"clean", BuildDate:"2021-12-16T11:41:01Z", GoVersion:"go1.17.5", Compiler:"gc", Platform:"linux/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?

➜ root@cluster3-worker2:~$ kubelet --version
Kubernetes v1.23.1
Here kubeadm is already installed in the wanted version, so we can run:

➜ root@cluster3-worker2:~$ kubeadm upgrade node
couldn't create a Kubernetes client from file "/etc/kubernetes/kubelet.conf": failed to load admin kubeconfig: open /etc/kubernetes/kubelet.conf: no such file or directory
To see the stack trace of this error execute with --v=5 or higher
```
This is usually the proper command to upgrade a node. But this error means that this node was never even initialised, so nothing to update here. This will be done later using kubeadm join. For now we can continue with kubelet and kubectl:
``` bash
➜ root@cluster3-worker2:~$ apt update
...
Fetched 5,775 kB in 2s (2,313 kB/s)                               
Reading package lists... Done
Building dependency tree       
Reading state information... Done
90 packages can be upgraded. Run 'apt list --upgradable' to see them.

➜ root@cluster3-worker2:~$ apt show kubectl -a | grep 1.24
Version: 1.24.3-00
Version: 1.24.2-00
Version: 1.24.1-00
Version: 1.24.0-00

➜ root@cluster3-worker2:~$ apt install kubectl=1.24.1-00 kubelet=1.24.1-00
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be upgraded:
  kubectl kubelet
2 upgraded, 0 newly installed, 0 to remove and 69 not upgraded.
Need to get 28.6 MB of archives.
After this operation, 9,044 kB disk space will be freed.
Get:1 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubectl amd64 1.24.1-00 [9,318 kB]
Get:2 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubelet amd64 1.24.1-00 [19.3 MB]
Fetched 28.6 MB in 2s (15.5 MB/s)  
(Reading database ... 112511 files and directories currently installed.)
Preparing to unpack .../kubectl_1.24.1-00_amd64.deb ...
Unpacking kubectl (1.24.1-00) over (1.23.1-00) ...
Preparing to unpack .../kubelet_1.24.1-00_amd64.deb ...
Unpacking kubelet (1.24.1-00) over (1.23.1-00) ...
Setting up kubectl (1.24.1-00) ...
Setting up kubelet (1.24.1-00) ...

➜ root@cluster3-worker2:~$ kubelet --version
Kubernetes v1.24.1
```
Now we're up to date with kubeadm, kubectl and kubelet. Restart the kubelet:
``` bash
➜ root@cluster3-worker2:~$ systemctl restart kubelet

➜ root@cluster3-worker2:~$ service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: activating (auto-restart) (Result: exit-code) since Thu 2022-08-04 11:31:25 UTC; 3s ago
       Docs: https://kubernetes.io/docs/home/
    Process: 35802 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (>
   Main PID: 35802 (code=exited, status=1/FAILURE)
```

We can ignore the errors and move into next step to generate the join command.

 

Add cluster3-master2 to cluster
First we log into the master1 and generate a new TLS bootstrap token, also printing out the join command:
``` bash
➜ ssh cluster3-master1

➜ root@cluster3-master1:~$ kubeadm token create --print-join-command
kubeadm join 192.168.100.31:6443 --token ez34if.qedae3br5r3mi7p2 --discovery-token-ca-cert-hash sha256:91f646b4fa8a0b69811ad1c412258c41fd76b7940d1a13802898728d8b5474c7

➜ root@cluster3-master1:~$ kubeadm token list
TOKEN                     TTL         EXPIRES                ...
7aqkr7.q92y1za324u1g9fy   <invalid>   2022-07-13T11:01:23Z   ...
ez34if.qedae3br5r3mi7p2   23h         2022-08-05T11:32:02Z   ...
tqddy8.r6yrlrgz6f0xwca6   <forever>   <never>                ...
```
We see the expiration of 23h for our token, we could adjust this by passing the ttl argument.

Next we connect again to cluster3-worker2 and simply execute the join command:

``` bash
➜ ssh cluster3-worker2

➜ root@cluster3-worker2:~$ kubeadm join 192.168.100.31:6443 --token leqq1l.1hlg4rw8mu7brv73 --discovery-token-3c9cf14535ebfac8a23a91132b75436b36df2c087aa99c433f79d531
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.


➜ root@cluster3-worker2:~$ service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Thu 2022-08-04 11:33:28 UTC; 50s ago
       Docs: https://kubernetes.io/docs/home/
   Main PID: 36138 (kubelet)
      Tasks: 15 (limit: 462)
     Memory: 54.2M
     CGroup: /system.slice/kubelet.service
             └─36138 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubele>
```
If you have troubles with kubeadm join you might need to run kubeadm reset.

This looks great though for us. Finally we head back to the main terminal and check the node status:
``` bash
➜ k get node
NAME               STATUS     ROLES           AGE   VERSION
cluster3-master1   Ready      control-plane   23d   v1.24.1
cluster3-worker1   Ready      <none>          23d   v1.24.1
cluster3-worker2   NotReady   <none>          51s   v1.24.1
```
Give it a bit of time till the node is ready.
``` bash
➜ k get node
NAME               STATUS     ROLES           AGE     VERSION
cluster3-master1   Ready      control-plane   23d     v1.24.1
cluster3-worker1   Ready      <none>          23d     v1.24.1
cluster3-worker2   Ready      <none>          2m24s   v1.24.1
```
We see cluster3-worker2 is now available and up to date.

 

 

## Question 21 | Create a Static Pod and Service
Task weight: 2%

 

Use context: `kubectl config use-context k8s-c3-CCC`

 

Create a Static Pod named `my-static-pod` in Namespace `default` on `cluster3-master1`. It should be of image `nginx:1.16-alpine` and have resource requests for `10m` CPU and `20Mi` memory.

Then create a `NodePort` Service named `static-pod-service` which exposes that static Pod on port 80 and check if it has Endpoints and if its reachable through the `cluster3-master1` internal IP address. You can connect to the internal node IPs from your main terminal.

 

#### Answer:
``` bash
➜ ssh cluster3-master1

➜ root@cluster1-master1:~$ cd /etc/kubernetes/manifests/

➜ root@cluster1-master1:~$ kubectl run my-static-pod \
    --image=nginx:1.16-alpine \
    -o yaml --dry-run=client > my-static-pod.yaml
```
Then edit the `my-static-pod.yaml` to add the requested resource requests:

``` yaml
# /etc/kubernetes/manifests/my-static-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: my-static-pod
  name: my-static-pod
spec:
  containers:
  - image: nginx:1.16-alpine
    name: my-static-pod
    resources:
      requests:
        cpu: 10m
        memory: 20Mi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
 

And make sure its running:
``` bash
➜ k get pod -A | grep my-static
NAMESPACE     NAME                             READY   STATUS   ...   AGE
default       my-static-pod-cluster3-master1   1/1     Running  ...   22s
```
Now we expose that static Pod:
``` bash
k expose pod my-static-pod-cluster3-master1 \
  --name static-pod-service \
  --type=NodePort \
  --port 80
```
This would generate a Service like:
```
 kubectl expose pod my-static-pod-cluster3-master1 --name static-pod-service --type=NodePort --port 80
```
``` yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: my-static-pod
  name: static-pod-service
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: my-static-pod
  type: NodePort
status:
  loadBalancer: {}
```
Then run and test:
``` bash
➜ k get svc,ep -l run=my-static-pod
NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/static-pod-service   NodePort   10.99.168.252   <none>        80:30352/TCP   30s

NAME                           ENDPOINTS      AGE
endpoints/static-pod-service   10.32.0.4:80   30s
Looking good.
```
 

 

## Question 22 | Check how long certificates are valid
Task weight: 2%

 

Use context: `kubectl config use-context k8s-c2-AC`

 

Check how long the `kube-apiserver` server certificate is valid on `cluster2-master1`. Do this with openssl or cfssl. Write the exipiration date into `/opt/course/22/expiration`.

Also run the correct `kubeadm` command to list the expiration dates and confirm both methods show the same date.

Write the correct `kubeadm` command that would renew the apiserver server certificate into `/opt/course/22/kubeadm-renew-certs.sh`.

 

#### Answer:
First let's find that certificate:
``` bash
➜ ssh cluster2-master1

➜ root@cluster2-master1:~$ find /etc/kubernetes/pki | grep apiserver
/etc/kubernetes/pki/apiserver.crt
/etc/kubernetes/pki/apiserver-etcd-client.crt
/etc/kubernetes/pki/apiserver-etcd-client.key
/etc/kubernetes/pki/apiserver-kubelet-client.crt
/etc/kubernetes/pki/apiserver.key
/etc/kubernetes/pki/apiserver-kubelet-client.key
```
Next we use openssl to find out the expiration date:
``` bash
➜ root@cluster2-master1:~$ openssl x509  -noout -text -in /etc/kubernetes/pki/apiserver.crt | grep Validity -A2
        Validity
            Not Before: Jan 14 18:18:15 2021 GMT
            Not After : Jan 14 18:49:40 2022 GMT
```
There we have it, so we write it in the required location on our main terminal:
``` text
# /opt/course/22/expiration
Jan 14 18:49:40 2022 GMT
```
And we use the feature from kubeadm to get the expiration too:
``` bash
➜ root@cluster2-master1:~# kubeadm certs check-expiration | grep apiserver
apiserver                Jan 14, 2022 18:49 UTC   363d        ca               no      
apiserver-etcd-client    Jan 14, 2022 18:49 UTC   363d        etcd-ca          no      
apiserver-kubelet-client Jan 14, 2022 18:49 UTC   363d        ca               no 
```
Looking good. And finally we write the command that would renew all certificates into the requested location:
``` text
# /opt/course/22/kubeadm-renew-certs.sh
kubeadm certs renew apiserver
```
 

 

## Question 23 | Kubelet client/server cert info
Task weight: 2%

 

Use context: `kubectl config use-context k8s-c2-AC`

 

Node `cluster2-worker1` has been added to the cluster using kubeadm and TLS bootstrapping.

Find the "Issuer" and "Extended Key Usage" values of the `cluster2-worker1`:

* kubelet client certificate, the one used for outgoing connections to the `kube-apiserver`.
* kubelet server certificate, the one used for incoming connections from the `kube-apiserver`.
Write the information into file `/opt/course/23/certificate-info.txt`.

Compare the "Issuer" and "Extended Key Usage" fields of both certificates and make sense of these.

 

#### Answer:
To find the correct kubelet certificate directory, we can look for the default value of the `--cert-dir` parameter for the kubelet. For this search for "kubelet" in the Kubernetes docs which will lead to: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet. We can check if another certificate directory has been configured using ps aux or in `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`.

First we check the kubelet client certificate:
``` bash
➜ ssh cluster2-worker1

➜ root@cluster2-worker1:~$ openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep Issuer
        Issuer: CN = kubernetes
        
➜ root@cluster2-worker1:~$ openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep "Extended Key Usage" -A1
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
Next we check the kubelet server certificate:

➜ root@cluster2-worker1:~$ openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep Issuer
          Issuer: CN = cluster2-worker1-ca@1588186506

➜ root@cluster2-worker1:~$ openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep "Extended Key Usage" -A1
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
```
We see that the server certificate was generated on the worker node itself and the client certificate was issued by the Kubernetes api. The "Extended Key Usage" also shows if its for client or server authentication.

More about this: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping

 

 

## Question 24 | NetworkPolicy
Task weight: 9%

 

Use context: `kubectl config use-context k8s-c1-H`

 

There was a security incident where an intruder was able to access the whole cluster from a single hacked backend Pod.

To prevent this create a NetworkPolicy called `np-backend` in Namespace `project-snake`. It should allow the `backend-*` Pods only to:

connect to `db1-*` Pods on port 1111
connect to `db2-*` Pods on port 2222
Use the app label of Pods in your policy.

After implementation, connections from `backend-*` Pods to `vault-*` Pods on port `3333` should for example no longer work.

 

#### Answer:
First we look at the existing Pods and their labels:
``` bash
➜ k -n project-snake get pod
NAME        READY   STATUS    RESTARTS   AGE
backend-0   1/1     Running   0          8s
db1-0       1/1     Running   0          8s
db2-0       1/1     Running   0          10s
vault-0     1/1     Running   0          10s

➜ k -n project-snake get pod -L app
NAME        READY   STATUS    RESTARTS   AGE     APP
backend-0   1/1     Running   0          3m15s   backend
db1-0       1/1     Running   0          3m15s   db1
db2-0       1/1     Running   0          3m17s   db2
vault-0     1/1     Running   0          3m17s   vault
```
We test the current connection situation and see nothing is restricted:
``` bash
➜ k -n project-snake get pod -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP          ...
backend-0   1/1     Running   0          4m14s   10.44.0.24  ...
db1-0       1/1     Running   0          4m14s   10.44.0.25  ...
db2-0       1/1     Running   0          4m16s   10.44.0.23  ...
vault-0     1/1     Running   0          4m16s   10.44.0.22  ...

➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.25:1111
database one

➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.23:2222
database two

➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.22:3333
vault secret storage
```
Now we create the NP by copying and chaning an example from the k8s docs:
``` bash
vim 24_np.yaml
```
``` yaml
# 24_np.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: project-snake
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress                    # policy is only about Egress
  egress:
    -                           # first rule
      to:                           # first condition "to"
      - podSelector:
          matchLabels:
            app: db1
      ports:                        # second condition "port"
      - protocol: TCP
        port: 1111
    -                           # second rule
      to:                           # first condition "to"
      - podSelector:
          matchLabels:
            app: db2
      ports:                        # second condition "port"
      - protocol: TCP
        port: 2222
```
The NP above has two rules with two conditions each, it can be read as:
``` text
allow outgoing traffic if:
  (destination pod has label app=db1 AND port is 1111)
  OR
  (destination pod has label app=db2 AND port is 2222)
```

Wrong example
Now let's shortly look at a wrong example:
``` yaml
# WRONG
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: project-snake
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    -                           # first rule
      to:                           # first condition "to"
      - podSelector:                    # first "to" possibility
          matchLabels:
            app: db1
      - podSelector:                    # second "to" possibility
          matchLabels:
            app: db2
      ports:                        # second condition "ports"
      - protocol: TCP                   # first "ports" possibility
        port: 1111
      - protocol: TCP                   # second "ports" possibility
        port: 2222
```
The NP above has one rule with two conditions and two condition-entries each, it can be read as:

allow outgoing traffic if:
``` text
  (destination pod has label app=db1 OR destination pod has label app=db2)
  AND
  (destination port is 1111 OR destination port is 2222)
Using this NP it would still be possible for backend-* Pods to connect to db2-* Pods on port 1111 for example which should be forbidden.
```

 

Create NetworkPolicy
We create the correct NP:
``` bash
k -f 24_np.yaml create
```
And test again:

``` bash
➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.25:1111
database one

➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.23:2222
database two

➜ k -n project-snake exec backend-0 -- curl -s 10.44.0.22:3333
^C
```
Also helpful to use kubectl describe on the NP to see how k8s has interpreted the policy.

Great, looking more secure. Task done.

 

 

## Question 25 | Etcd Snapshot Save and Restore
Task weight: 8%

 

Use context: kubectl `config use-context k8s-c3-CCC`

 

Make a backup of etcd running on `cluster3-master1` and save it on the master node at `/tmp/etcd-backup.db`.

Then create a Pod of your kind in the cluster.

Finally restore the backup, confirm the cluster is still working and that the created Pod is no longer with us.

 

#### Answer:
Etcd Backup
First we log into the master and try to create a snapshop of etcd:
``` bash
➜ ssh cluster3-master1

➜ root@cluster3-master1:~$ ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db
Error:  rpc error: code = Unavailable desc = transport is closing
But it fails because we need to authenticate ourselves. For the necessary information we can check the etc manifest:

➜ root@cluster3-master1:~$ vim /etc/kubernetes/manifests/etcd.yaml
```
We only check the etcd.yaml for necessary information we don't change it.
``` yaml
# /etc/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.100.31:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt                           # use
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.100.31:2380
    - --initial-cluster=cluster3-master1=https://192.168.100.31:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key                            # use
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.100.31:2379   # use
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.100.31:2380
    - --name=cluster3-master1
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt                    # use
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    image: k8s.gcr.io/etcd:3.3.15-0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: etcd
    resources: {}
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd                                                     # important
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```
But we also know that the api-server is connecting to etcd, so we can check how its manifest is configured:
``` bash
➜ root@cluster3-master1:~$ cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
```
We use the authentication information and pass it to etcdctl:
``` bash
➜ root@cluster3-master1:~$ ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key

Snapshot saved at /tmp/etcd-backup.db
```

> NOTE: Dont use snapshot status because it can alter the snapshot file and render it invalid

 

Etcd restore
Now create a Pod in the cluster and wait for it to be running:
``` bash
➜ root@cluster3-master1:~# kubectl run test --image=nginx
pod/test created

➜ root@cluster3-master1:~# kubectl get pod -l run=test -w
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          60s
```

> NOTE: If you didn't solve questions 18 or 20 and cluster3 doesn't have a ready worker node then the created pod might stay in a Pending state. This is still ok for this task.

 

Next we stop all controlplane components:
``` bash
root@cluster3-master1:~$ cd /etc/kubernetes/manifests/

root@cluster3-master1:/etc/kubernetes/manifests$ mv * ..

root@cluster3-master1:/etc/kubernetes/manifests$ watch crictl ps
```
Now we restore the snapshot into a specific directory:
``` bash
➜ root@cluster3-master1:~$ ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
--data-dir /var/lib/etcd-backup \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key

2020-09-04 16:50:19.650804 I | mvcc: restore compact to 9935
2020-09-04 16:50:19.659095 I | etcdserver/membership: added member 8e9e05c52164694d [http://localhost:2380] to cluster cdf818194e3a8c32
We could specify another host to make the backup from by using etcdctl --endpoints http://IP, but here we just use the default value which is: http://127.0.0.1:2379,http://127.0.0.1:4001.
```
The restored files are located at the new folder /var/lib/etcd-backup, now we have to tell etcd to use that directory:
``` bash
➜ root@cluster3-master1:~$ vim /etc/kubernetes/etcd.yaml
```
``` yaml
# /etc/kubernetes/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
...
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd-backup                # change
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```
Now we move all controlplane yaml again into the manifest directory. Give it some time (up to several minutes) for etcd to restart and for the api-server to be reachable again:
``` bash
root@cluster3-master1:/etc/kubernetes/manifests$ mv ../*.yaml .

root@cluster3-master1:/etc/kubernetes/manifests$ watch crictl ps
Then we check again for the Pod:

➜ root@cluster3-master1:~$ kubectl get pod -l run=test
No resources found in default namespace.
```
Awesome, backup and restore worked as our pod is gone.

 

 

## Extra Question 1 | Find Pods first to be terminated
Use context: `kubectl config use-context k8s-c1-H`

 

Check all available Pods in the Namespace `project-c13` and find the names of those that would probably be terminated first if the nodes run out of resources (cpu or memory) to schedule all Pods. Write the Pod names into `/opt/course/e1/pods-not-stable.txt`.

 

#### Answer:
When available cpu or memory resources on the nodes reach their limit, Kubernetes will look for Pods that are using more resources than they requested. These will be the first candidates for termination. If some Pods containers have no resource requests/limits set, then by default those are considered to use more than requested.

Kubernetes assigns Quality of Service classes to Pods based on the defined resources and limits, read more here: https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod

Hence we should look for Pods without resource requests defined, we can do this with a manual approach:
``` bash
k -n project-c13 describe pod | less -p Requests # describe all pods and highlight Requests
```
Or we do:
```
k -n project-c13 describe pod | egrep "^(Name:|    Requests:)" -A1
```
We see that the Pods of Deployment c13-3cc-runner-heavy don't have any resources requests specified. Hence our answer would be:
``` text
# /opt/course/e1/pods-not-stable.txt
c13-3cc-runner-heavy-65588d7d6-djtv9map
c13-3cc-runner-heavy-65588d7d6-v8kf5map
c13-3cc-runner-heavy-65588d7d6-wwpb4map
o3db-0
o3db-1 # maybe not existing if already removed via previous scenario 
```
To automate this process you could use jsonpath like this:
``` bash
➜ k -n project-c13 get pod \
  -o jsonpath="{range .items[*]} {.metadata.name}{.spec.containers[*].resources}{'\n'}"

 c13-2x3-api-86784557bd-cgs8gmap[requests:map[cpu:50m memory:20Mi]]
 c13-2x3-api-86784557bd-lnxvjmap[requests:map[cpu:50m memory:20Mi]]
 c13-2x3-api-86784557bd-mnp77map[requests:map[cpu:50m memory:20Mi]]
 c13-2x3-web-769c989898-6hbgtmap[requests:map[cpu:50m memory:10Mi]]
 c13-2x3-web-769c989898-g57nqmap[requests:map[cpu:50m memory:10Mi]]
 c13-2x3-web-769c989898-hfd5vmap[requests:map[cpu:50m memory:10Mi]]
 c13-2x3-web-769c989898-jfx64map[requests:map[cpu:50m memory:10Mi]]
 c13-2x3-web-769c989898-r89mgmap[requests:map[cpu:50m memory:10Mi]]
 c13-2x3-web-769c989898-wtgxlmap[requests:map[cpu:50m memory:10Mi]]
 c13-3cc-runner-98c8b5469-dzqhrmap[requests:map[cpu:30m memory:10Mi]]
 c13-3cc-runner-98c8b5469-hbtdvmap[requests:map[cpu:30m memory:10Mi]]
 c13-3cc-runner-98c8b5469-n9lswmap[requests:map[cpu:30m memory:10Mi]]
 c13-3cc-runner-heavy-65588d7d6-djtv9map[]
 c13-3cc-runner-heavy-65588d7d6-v8kf5map[]
 c13-3cc-runner-heavy-65588d7d6-wwpb4map[]
 c13-3cc-web-675456bcd-glpq6map[requests:map[cpu:50m memory:10Mi]]
 c13-3cc-web-675456bcd-knlpxmap[requests:map[cpu:50m memory:10Mi]]
 c13-3cc-web-675456bcd-nfhp9map[requests:map[cpu:50m memory:10Mi]]
 c13-3cc-web-675456bcd-twn7mmap[requests:map[cpu:50m memory:10Mi]]
 o3db-0{}
 o3db-1{}
 ```
This lists all Pod names and their requests/limits, hence we see the three Pods without those defined.

Or we look for the Quality of Service classes:
``` bash
➜ k get pods -n project-c13 \
  -o jsonpath="{range .items[*]}{.metadata.name} {.status.qosClass}{'\n'}"

c13-2x3-api-86784557bd-cgs8g Burstable
c13-2x3-api-86784557bd-lnxvj Burstable
c13-2x3-api-86784557bd-mnp77 Burstable
c13-2x3-web-769c989898-6hbgt Burstable
c13-2x3-web-769c989898-g57nq Burstable
c13-2x3-web-769c989898-hfd5v Burstable
c13-2x3-web-769c989898-jfx64 Burstable
c13-2x3-web-769c989898-r89mg Burstable
c13-2x3-web-769c989898-wtgxl Burstable
c13-3cc-runner-98c8b5469-dzqhr Burstable
c13-3cc-runner-98c8b5469-hbtdv Burstable
c13-3cc-runner-98c8b5469-n9lsw Burstable
c13-3cc-runner-heavy-65588d7d6-djtv9 BestEffort
c13-3cc-runner-heavy-65588d7d6-v8kf5 BestEffort
c13-3cc-runner-heavy-65588d7d6-wwpb4 BestEffort
c13-3cc-web-675456bcd-glpq6 Burstable
c13-3cc-web-675456bcd-knlpx Burstable
c13-3cc-web-675456bcd-nfhp9 Burstable
c13-3cc-web-675456bcd-twn7m Burstable
o3db-0 BestEffort
o3db-1 BestEffort
```
Here we see three with BestEffort, which Pods get that don't have any memory or cpu limits or requests defined.

A good practice is to always set resource requests and limits. If you don't know the values your containers should have you can find this out using metric tools like Prometheus. You can also use kubectl top pod or even kubectl exec into the container and use top and similar tools.

 

 

## Extra Question 2 | Curl Manually Contact API
Use context: kubectl `config use-context k8s-c1-H`

 

There is an existing ServiceAccount `secret-reader` in Namespace `project-hamster`. Create a Pod of image `curlimages/curl:7.65.3` named `tmp-api-contact` which uses this ServiceAccount. Make sure the container keeps running.

Exec into the Pod and use curl to access the Kubernetes Api of that cluster manually, listing all available secrets. You can ignore insecure https connection. Write the command(s) for this into file `/opt/course/e4/list-secrets.sh`.

 

#### Answer:
https://kubernetes.io/docs/tasks/run-application/access-api-from-pod

It's important to understand how the Kubernetes API works. For this it helps connecting to the api manually, for example using curl. You can find information fast by search in the Kubernetes docs for "curl api" for example.

First we create our Pod:
``` bash
k run tmp-api-contact \
  --image=curlimages/curl:7.65.3 $do \
  --command > e2.yaml -- sh -c 'sleep 1d'
```
``` bash
vim e2.yaml
```
Add the service account name and Namespace:
``` yaml
# e2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: tmp-api-contact
  name: tmp-api-contact
  namespace: project-hamster          # add
spec:
  serviceAccountName: secret-reader   # add
  containers:
  - command:
    - sh
    - -c
    - sleep 1d
    image: curlimages/curl:7.65.3
    name: tmp-api-contact
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
Then run and exec into:

``` bash
k -f 6.yaml create

k -n project-hamster exec tmp-api-contact -it -- sh
```
Once on the container we can try to connect to the api using curl, the api is usually available via the Service named kubernetes in Namespace default (You should know how dns resolution works across Namespaces.). Else we can find the endpoint IP via environment variables running env.

So now we can do:
``` bash
curl https://kubernetes.default
curl -k https://kubernetes.default # ignore insecure as allowed in ticket description
curl -k https://kubernetes.default/api/v1/secrets # should show Forbidden 403
```
The last command shows 403 forbidden, this is because we are not passing any authorisation information with us. The Kubernetes Api Server thinks we are connecting as system:anonymous. We want to change this and connect using the Pods ServiceAccount named secret-reader.

We find the the token in the mounted folder at /var/run/secrets/kubernetes.io/serviceaccount, so we do:
``` bash
➜ TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
➜ curl -k https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer ${TOKEN}"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0{
  "kind": "SecretList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/secrets",
    "resourceVersion": "10697"
  },
  "items": [
    {
      "metadata": {
        "name": "default-token-5zjbd",
        "namespace": "default",
        "selfLink": "/api/v1/namespaces/default/secrets/default-token-5zjbd",
        "uid": "315dbfd9-d235-482b-8bfc-c6167e7c1461",
        "resourceVersion": "342",
...
```
Now we're able to list all Secrets, registering as the ServiceAccount secret-reader under which our Pod is running.

To use encrypted https connection we can run:
``` bash
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
curl --cacert ${CACERT} https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer ${TOKEN}"
```
For troubleshooting we could also check if the ServiceAccount is actually able to list Secrets using:
``` bash
➜ k auth can-i get secret --as system:serviceaccount:project-hamster:secret-reader
yes
```
Finally write the commands into the requested location:
``` text
# /opt/course/e4/list-secrets.sh
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -k https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer ${TOKEN}"
```