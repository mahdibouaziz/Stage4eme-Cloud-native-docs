# Cluster Upgrade 

In this Demo we will upgrade the cluster bootstrapped with kubeadm with all the components. 

``` bash
mohamed@master:~$ kubeadm upgrade plan
```
This command will give you all the versions of the master node components and the new available versions in addition to the kubelet versions on worker node too !

If you want upgrade to version not available on the upgrade plan so you need to upgrade the kubeadm first !

Let's make update to our repository First!
``` bash
mohamed@master:~$ sudo apt update
```
Now Let's drain the master node to make it unschedulable 

``` bash
mohamed@master:~$ kubectl drain master --ignore-daemonsets
```
After making the master unschedulable. We can upgrade the kubeadm to 1.23.0-00 without any problem

``` bash
mohamed@master:~$ sudo apt install kubeadm=1.23.0-00
```

> In this example we assume that we have kubeadm 1.22. In case you have 1.21 you must upgrade to 1.22 then from 1.22 to 1.23. In Kubernetes, upgrading is mandatory to be done step by step :(

Let's upgrade the master node components !
``` bash
mohamed@master:~$ sudo kubeadm upgrade apply v1.23.0
---
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.23.x". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```
After upgrading the kubeadm and the master node components, we need to upgrade the kubelet on the master node and the other worker nodes! Let's start by the master node and ring it back online by marking it schedulable:

``` bash
mohamed@master:~$ sudo apt install kubelet=1.23.0-00
```
After upgrading the kubelet successfully we must restart the kubelet system service to apply the changes !

``` bash
mohamed@master:~$ sudo systemctl restart kubelet.service
```
Now it's time to use `kubectl uncordon` command to bring the master node back!
``` bash
mohamed@master:~$ kubectl uncordon master
```
Now let's moving the worker nodes! First , as we do with master node, we need to drain the worker node to make it unschedulable 
``` bash
mohamed@master:~$ kubectl drain worker1 --ignore-daemonsets
```
As usual we start by updating the repository 
``` bash
mohamed@worker1:~$ sudo apt update
```
After updating the repository without any problem! It's time to update the kubelet
``` bash
mohamed@worker1:~$ sudo apt install kubelet=1.23.0-00
```
After upgrading the kubelet successfully we must restart the kubelet system service to apply the changes !

``` bash
mohamed@worker1:~$ sudo systemctl restart kubelet.service
```
Now it's time to use `kubectl uncordon` command to bring the worker node back to work ! 
``` bash
mohamed@master:~$ kubectl uncordon worker1
```


