# OS Upgrades

When a node in a cluster goes down, the PODs running inside it automatically become inaccessible. Users may not be able to access cluster services hosted in the PODs. PODs with instances running in other nodes, however, will have their workloads unaffected. If the failed node comes back online immediately, the Kubelet service starts, and the PODs become available. 

However, if the node stays unavailable for 5 minutes the PODs are permanently terminated. PODs that were part of a ReplicaSet are recreated inside other nodes. The time it takes to wait before PODs are terminated is known as the POD Eviction Timeout, and is set on the Kube-Controller-Manager with a default value of 5 minutes:

``` bash
$ kube-controller-manager --pod-eviction-timeout= 5m0s
```
If a node comes back online after the POD Eviction Timeout, it is blank with no PODs scheduled on it. This means that only quick updates can be performed on the nodes and they should be rebooted before the timeout period or their PODs to be available. 

For node updates that are expected to take a longer time, like an Operating System Upgrade, the `drain` command is used. This redistributes the PODs to other nodes in the cluster:


``` bash
$ kubectl drain <node>
```

When a node is drained, the PODs are gracefully terminated in the node then recreated in other cluster nodes. The node being drained is marked as `unschedulable` so no other PODs can be assigned to it. Even when it comes back online, the node is still `unschedulable` until the developers lift the tag off using the `uncordon` command:

``` bash
$ kubectl uncordon <node>
```

The node does not recover any PODs previously scheduled on it. Rather, newer PODs in the cluster can be scheduled in the cluster once it has been uncordoned.

The `cordon` command marks a node as unschedulable. Unlike the `drain` command, however, this one does not terminate existing PODs on a node. It just ensures that no newer PODs are `scheduled` on the node:
``` bash
$ kubectl cordon  <node>
```