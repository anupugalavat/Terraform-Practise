# VMware Terraform Module for APM

This module will provision infrastructure in provided Vsphere Infrastructure using Vsphere and Nsx-T Provider for Application Performance Management (APM).

It provisions the below components:

* Disks

```
* Dynatace opt storage voulme
* Long term volume cassandra voulme
* Long term volume Logsearch voulme
* Dynatrace transaction data voulme
* Nfs backup voulme
```

* Security groups

```
Security group to filter inbound and outbound traffic between 
* agent whitelisted IPs
* UI whitelisted IPs
* Dynatrace sever
* Nfs server
* Dynatrace-cluster-active-gate Server
* Jump Box IPs
```

* Virtual Machines
```
* Dynatrace sever
* Nfs server
* Dynatrace-cluster-active-gate Server
```

* IPs
```
* Public IP
```

The Complete Architecture Diagram is as below,

![Overview Diagram](diagram-product-apm.png?raw=true "Overview Diagram")

Diagram file can be edited with [draw.io](https://draw.io).


