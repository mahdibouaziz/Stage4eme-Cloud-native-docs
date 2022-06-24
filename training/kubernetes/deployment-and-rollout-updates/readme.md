
# Deployments and Rollout Updates:
## Deployments
Kubernetes Deployments are one of the most potent controllers you can use.
They not only maintain a specified number of pods but also ensure that any updates
you want to make do not cause downtime. 
Behind the scenes, Deployments use ReplicaSets to manage pods.
### Creating Deployment
Example of Deployment manifest :

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: nginx-deployment
    labels:
        role: webserver
spec:
    replicas: 3
    selector:
        matchLabels:
            role: webserver
    template:
        metadata:
            labels:
                role: webserver
        spec:
            containers:
            - name: frontend
              image: httpd  # we use wrong image for the demo !
              ports:
              - containerPort: 80
```
Let's now create the deployment! :
``` bash
justk8s@justk8s-master:~$ kubectl apply -f deployments.yaml
deployment.apps/nginx-deployment created
```
We can list the pods of the deployments by `kubectl get pods`
``` bash
justk8s@justk8s-master:~$ kubectl get pods

NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7d69654c99-5ck24   1/1     Running   0          98s
nginx-deployment-7d69654c99-6826c   1/1     Running   0          98s
nginx-deployment-7d69654c99-qwj2v   1/1     Running   0          98s
``` 
We can also display the ReplicaSet used by the Deployment

``` Bash
justk8s@justk8s-master:~$ kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7d69654c99   1         1         1       10m
```

### Scaling and Updating a Deployment
#### Scaling a Deployment 
You can use Deployments to scale up, or down, the number of pods it is managing. You can also configure it to respond to CPU load by creating, or killing pods, subject to a maximum and minimum number

you can scale up or down using the `kubectl scale`
``` bash
justk8s@justk8s-master:~$  kubectl scale deployment/nginx-deployment --replicas=10
deployment.apps/nginx-deployment scaled
```
you can setup an autoscaler for your Deployment and choose the minimum and maximum number of Pods you want to run based on the CPU utilization of your existing Pods:
``` bash
justk8s@justk8s-master:~$  kubectl scale deployment/nginx-deployment --min=10 --max=15 --cpu-percent=80
deployment.apps/nginx-deployment scaled
```
#### Updating a Deployment 
You can update the Deployment either by using the `kubectl set image` command or by `kubectl edit` command. In our previous example we choose the wrong container image (apache), So we must change it to nginx image
> **_NOTE:_**  A Deployment's rollout is triggered if and only if the Deployment's Pod template (is changed, for example if the labels or container images of the template are updated. Other updates, such as scaling the Deployment, do not trigger a rollout.
##### 1- Update the Deployment with kubectl set image: 
This command is too fast when you want to change something like image
``` bash
justk8s@justk8s-master:~$ kubectl set image deployment/nginx-deployment frontend=nginx
deployment.apps/nginx-deployment image updated
```
##### 2- Update the Deployment with kubectl edit:
When you run this command. The manifest file of the current state of the deployment will be opened with vim or vi. Change the image name to nginx and save the changes
``` bash
justk8s@justk8s-master:~$ kubectl edit deployment/nginx-deployment
deployment.apps/nginx-deployment edited
```
After Change The Pod's template a rollout update will be triggered and a new ReplicaSet will be created. Let's run the `kubectl get rs ` to see what happend
``` bash
justk8s@justk8s-master:~$ kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7d69654c99   0         0         0       13m
nginx-deployment-7fcb994c6c   2         2         2       9s
```
## Rollout Update
Deployments support rollover updates in which you can interrupt an ongoing deployment update and instruct the Deployment controller to start the new update immediately without causing an application outage. Kubernetes maintains a list of the recent deployments. You can use this list to roll back an update and you can also choose a specific deployment to roll back to by specifying its revision number. You can use Deployments to scale up, or down, the number of pods it is managing

When we change the image of the container a Rollout Update is triggered. To see what happend lets run the following command :
``` bash 
justk8s@justk8s-master:~$  kubectl describe deployments
...
...

 Type    Reason             Age                From                   Message
  ----    ------             ----               ----                   -------
  Normal  ScalingReplicaSet  45m (x2 over 62m)  deployment-controller  Scaled down replica set nginx-deployment-7d69654c99 to 0
  Normal  ScalingReplicaSet  12s (x2 over 45m)  deployment-controller  Scaled up replica set nginx-deployment-7d69654c99 to 1
  Normal  ScalingReplicaSet  7s                 deployment-controller  Scaled down replica set nginx-deployment-7fcb994c6c to 1
  Normal  ScalingReplicaSet  7s                 deployment-controller  Scaled up replica set nginx-deployment-7d69654c99 to 2
  Normal  ScalingReplicaSet  2s                 deployment-controller  Scaled down replica set nginx-deployment-7fcb994c6c to 0
```
The Deployment delete a pod from the previous ReplicaSet and add a the new one to the new ReplicaSet to ensure the high availability 
<center>
<img src="images/roll-out-update.png" style="width:900px">
</center>

### Checking Rollout History of a Deployment 
You can list the history (revisions) of the deployment by running the following command :
``` Bash
justk8s@justk8s-master:~$ kubectl rollout history deployment/nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```
The `CHANGE-CAUSE` is the description of the rolling update. You can specify the `CHANGE-CAUSE` message either by running the `kubectl annotate` after the update directly or add `--record=true` to save the command that update the deployment
Example :
``` bash
justk8s@justk8s-master:~$ kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause="image updated to nginx"
deployment.apps/nginx-deployment annotated

justk8s@justk8s-master:~$ kubectl rollout history deployment/nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         image updated to nginx
```
To see the details of the rollout update you can run the `kubectl rollout history` and specify the number of the revision

``` bash
justk8s@justk8s-master:~$ kubectl rollout history deployment/nginx-deployment --revision=2
deployment.apps/nginx-deployment with revision #2
Pod Template:
  Labels:       pod-template-hash=7fcb994c6c
        role=webserver
  Annotations:  kubernetes.io/change-cause: image updated to nginx
  Containers:
   frontend:
    Image:      nginx
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```
### Rolling Back to a Previous Revision:

To rollback the Deployment from the current version to the previous version you can run `kubectl rollout undo` command:

``` bash 
justk8s@justk8s-master:~$ kubectl rollout undo deployment/nginx-deployment
deployment.apps/nginx-deployment rolled back
```
To rollback to a specific version by specifying it with `--to-revision` options:
``` bash 
justk8s@justk8s-master:~$ kubectl rollout undo deployment/nginx-deployment --to-revision=2
deployment.apps/nginx-deployment rolled back
```
