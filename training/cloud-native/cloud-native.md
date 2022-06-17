# Getting familiar with Cloud Native
Cloud Native technologies, also called cloud native stack, enable organizations to build and run scalable applications, cloud native applications, in modern and dynamic environments (public, private, and hybrid cloud) whiling exploiting innovations in cloud computing to the fullest. An example of these technologies are containers and microservices.

*Cloud Native Foundation’s Official Glossary: [Cloud Native Tech](https://glossary.cncf.io/cloud-native-tech/)*

In addition, cloud-native apps commonly follow the principles of the 12-factor apps framework. They are built around:
- **Performance:** the application is designed with scalability in mind and built to perform well at scale. 
- **Elasticity:** the application is built using small, scalable components that can be scaled horizontally with ease. 
- **Resilience:** the application is highly resilient to failure. Components can fail and are easily and automatically replaced, without disrupting the operation of other components.
- **Security:** the application is built with security in mind, operating under the assumption that an attacker has already accessed the network, and should not be able to compromise the application or its data. 

There are a number of advantages to a cloud-native architecture:
- **Cost**
- **Reliability**
- **Agility**
- **Flexibility**

*Cloud Native Wiki by Aqua: [Cloud Native Architecture](https://www.aquasec.com/cloud-native-academy/cloud-native-applications/cloud-native-architecture/)*

Unlike traditional architecture which focuses on the resilience and performance of a small and a fixed number of components, the cloud native architecture focuses on optimizing systems for the capabilities of the cloud thus achieving resilience and scale through horizontal scaling, distributed processing, and automating the replacement of failed components.

Some principles of cloud native architecture are:
- **Design for automation:** Automated processes can repair, scale, deploy your system far faster than people can. Some common areas for automating cloud-native systems are infrastructure, CI/CD, scale up and scale down, monitoring and automated recovery. 
- **Be smart with state:** Architecting systems to be intentional about when, and how, you store state, and design components to be stateless wherever you can. Stateless components are easy to scale, repair, roll-back, and load-balance across.
- **Favor managed services:** Managed services can often save the organization hugely in time and operational overhead.
- **Practice defense in depth:** Cloud-native architectures have their origins in internet-facing services, and so have always needed to deal with external attacks. Therefore they adopt an approach of defense-in-depth by applying authentication between each component, and by minimizing the trust between those components (even if they are 'internal'). Each component in a design should seek to protect itself from the other components. This not only makes the architecture very resilient, it also makes the resulting services easier to deploy in a cloud environment, where there may not be a trusted network between the service and its users.

*Google Cloud: [Principles for Cloud Native Architecture](https://cloud.google.com/blog/products/application-development/5-principles-for-cloud-native-architecture-what-it-is-and-how-to-master-it)*
