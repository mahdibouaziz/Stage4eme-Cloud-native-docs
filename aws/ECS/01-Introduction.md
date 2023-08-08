# What is Amazon Elastic Container Service

- Amazon Elastic Container Service (Amazon ECS) is a **fully managed container orchestration service** that helps you easily deploy, manage, and scale containerized applications.
- You can run and scale your container workloads across AWS Regions in the cloud, and on-premises, without the complexity of managing a control plane.

## Amazon ECS terminology and components

- There are three layers in Amazon ECS:
  - **Capacity** `EC2 Instances - Fargate - On premises` - The infrastructure where your containers run
  - **Controller** `Amazon ECS Scheduler` - Deploy and manage your applications that run on the containers
  - **Provisioning** `AWS Console - AWS CLI - AWS SDK` - The tools that you can use to interface with the scheduler to deploy and manage your applications and containers

## Application lifecycle

- To deploy applications on Amazon ECS, your application components must be configured to run in containers.
- After you create and store your image, you create an Amazon ECS `task definition`.
- A `task definition` is a **blueprint for your application**. It is a text file in JSON format that describes the **parameters** and **one or more containers that form your application**.
  - For example, you can use it to specify the image and parameters for the operating system, which containers to use, which ports to open for your application, and what data volumes to use with the containers in the task.

<br/>

- After you define your `task definition`, you deploy it as either a `service` or a `task` on your cluster.
- A cluster is a logical grouping of tasks or services that runs on the capacity infrastructure that is registered to a cluster.
- A task is the instantiation of a task definition within a cluster. You can run a `standalone task`, or you can run a `task as part of a service`.
  - A service is like a Desployment in K8s
  - A task is like a Pod in K8s

<br/>

- You can use an Amazon ECS service to run and maintain your desired number of tasks simultaneously in an Amazon ECS cluster. How it works is that, if any of your tasks fail or stop for any reason, the Amazon ECS service scheduler launches another instance based on your task definition. It does this to replace it and thereby maintain your desired number of tasks in the service.

- The `container agent` runs on each container instance within an Amazon ECS cluster. The agent sends information about the current running tasks and resource utilization of your containers to Amazon ECS. It starts and stops tasks whenever it receives a request from Amazon ECS.
  - Container agent is like the kubelet in K8s

## ECS Features

- Options to run your applications on `Amazon EC2 instances`, a `serverless environment`, or `on-premises VMs`.
- Integration with AWS Identity and Access Management (IAM). You can assign granular permissions for each of your containers. This allows for a high level of isolation when building your applications. In other words, you can launch your containers with the security and compliance levels that you've come to expect from AWS.
- AWS managed container orchestration with operational best practices built-in, and no control plane, nodes, or add-ons for you to manage. It natively integrates with both AWS and third-party tools to make it easier for teams to focus on building the applications, not the environment.
- Multiple options for a way to interconnect your applications.
  - `Service Discovery` - Integrates services with AWS Cloud Map namespaces to add entries (specifically, AWS Cloud Map service instances) to the namespace for each task in the Amazon ECS service. To connect, an app resolves these entries as DNS hostname records or uses the AWS Cloud Map API to get the IP address of the tasks.
  - `Amazon ECS Service Connect` - Define logical names for your service endpoints and use them in your client applications to connect to dependencies.
- Monitoring and logging
  - Use Amazon CloudWatch to average and aggregate CPU and memory utilization of running tasks. Set alarms to indicate when you need to increase or decrease capacity.
  - Use AWS CloudTrail to record API calls from the management console, AWS SDKs, and AWS Command Line Interface.
  - Use AWS Config to monitor and track how resources were configured, how they relate to one another, and how the configurations and relationships change over time.

## Common use cases in Amazon ECS

- Fargate is suitable for:

  - Large workloads that need to be optimized for low overhead
  - Small workloads that have occasional brust
  - Tiny workloads
  - Batch workloads

- EC2 is suitabe for:
  - Workload that require consistently high CPU core and memory usage
  - Large workloads that need to be optimized for price
  - Your applications need to access persistent storage
  - You must directly manage your infrastructure
