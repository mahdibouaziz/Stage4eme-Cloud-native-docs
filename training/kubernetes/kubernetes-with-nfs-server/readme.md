``` yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  nfs:
    server: 192.168.1.80
    path: "/mnt/nfs-data"

```
``` yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
        storage: 100Mi

```
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
              image: nginx  # we use wrong image for the demo !
              ports:
                - name: nginx-port
                  containerPort: 80
              volumeMounts:
                - name: nfs
                  mountPath: /usr/share/nginx/html
            volumes:
            - name: nfs
              persistentVolumeClaim:
                claimName: pvc-nfs
``` 
``` bash 
 kubectl apply -f nfs-pv.yaml
persistentvolume/pv-nfs created
mohamed@master:~/k8s/nfs-pv$ kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv-nfs   100Mi      RWX            Retain           Available           nfs                     4s





mohamed@master:~/k8s/nfs-pv$ kubectl apply -f nfs-pvc.yaml
persistentvolumeclaim/pvc-nfs created
mohamed@master:~/k8s/nfs-pv$ kubectl get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Bound    pv-nfs   100Mi      RWX            nfs            3s



mohamed@master:~/k8s/nfs-pv$ kubectl apply -f nginx-deployment.yaml
deployment.apps/nginx-deployment created
mohamed@master:~/k8s/nfs-pv$ kubectl get pods
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7976956b49-fgbb4   0/1     ContainerCreating   0          3s
nginx-deployment-7976956b49-hzrmm   0/1     ContainerCreating   0          3s
nginx-deployment-7976956b49-kg5tx   0/1     ContainerCreating   0          3s
mohamed@master:~/k8s/nfs-pv$





mohamed@master:~/k8s/nfs-pv$ kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7976956b49-fgbb4   1/1     Running   0          16s
nginx-deployment-7976956b49-hzrmm   1/1     Running   0          16s
nginx-deployment-7976956b49-kg5tx   1/1     Running   0          16s


mohamed@master:~/k8s/nfs-pv$ kubectl exec --stdin --tty nginx-deployment-7976956b49-fgbb4 -- /bin/bash
root@nginx-deployment-7976956b49-fgbb4:/# ls
bin  boot  dev  docker-entrypoint.d  docker-entrypoint.sh  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@nginx-deployment-7976956b49-fgbb4:/# cd /usr/share/nginx/html/
root@nginx-deployment-7976956b49-fgbb4:/usr/share/nginx/html# ls
file
root@nginx-deployment-7976956b49-fgbb4:/usr/share/nginx/html# touch "hi from the other side!"
root@nginx-deployment-7976956b49-fgbb4:/usr/share/nginx/html# ls
 file  'hi from the other side!'
root@nginx-deployment-7976956b49-fgbb4:/usr/share/nginx/html# exit
exit
mohamed@master:~/k8s/nfs-pv$ kubectl exec --stdin --tty nginx-deployment-7976956b49-kg5tx -- /bin/bash
root@nginx-deployment-7976956b49-kg5tx:/# cd /usr/share/nginx/html/
root@nginx-deployment-7976956b49-kg5tx:/usr/share/nginx/html# ls
 file  'hi from the other side!'
root@nginx-deployment-7976956b49-kg5tx:/usr/share/nginx/html# exit
exit
mohamed@master:~/k8s/nfs-pv$ kubectl delete -f nginx-deployment.yaml
deployment.apps "nginx-deployment" deleted
mohamed@master:~/k8s/nfs-pv$ kubectl delete -f nginx-deployment.yaml
Error from server (NotFound): error when deleting "nginx-deployment.yaml": deployments.apps "nginx-deployment" not found
mohamed@master:~/k8s/nfs-pv$ kubectl apply -f nginx-deployment.yaml
deployment.apps/nginx-deployment created
mohamed@master:~/k8s/nfs-pv$ kubectl get pods
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7976956b49-7d5vw   0/1     ContainerCreating   0          3s
nginx-deployment-7976956b49-9r5gx   0/1     ContainerCreating   0          3s
nginx-deployment-7976956b49-fdq7w   0/1     ContainerCreating   0          3s
mohamed@master:~/k8s/nfs-pv$ kubectl get pods
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7976956b49-7d5vw   1/1     Running             0          10s
nginx-deployment-7976956b49-9r5gx   0/1     ContainerCreating   0          10s
nginx-deployment-7976956b49-fdq7w   1/1     Running             0          10s
mohamed@master:~/k8s/nfs-pv$ kubectl exec --stdin --tty nginx-deployment-7976956b49-7d5vw -- /bin/bash
root@nginx-deployment-7976956b49-7d5vw:/# cd /usr/share/nginx/html/
root@nginx-deployment-7976956b49-7d5vw:/usr/share/nginx/html# ls
 file  'hi from the other side!'
root@nginx-deployment-7976956b49-7d5vw:/usr/share/nginx/html# exit
exit
mohamed@master:~/k8s/nfs-pv$

```