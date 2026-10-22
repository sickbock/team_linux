# Team Linux

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with linux](#setup)
    * [What linux affects](#what-linux-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with linux](#beginning-with-linux)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description
This repository should contain Puppet data to control everything that is administered only bhe the Linux administration team.

Therefore this repository is used to manage all _Puppet profiles_ that are responsible for managing RHEL systems and all _Puppet roles_ for nodes or groups of nodes under the responsibility of the Linux aministration team.

## Setup

### What linux affects
Profiles maintained via this repository should control basic system administration like infrastructure related configuration (like boot configuration and DNS -, authentication -, time -, auditing servers, ...). These profiles include
* wrappers to apply specific component modules
* wrappers to apply certain configurations to specific nodes (based on facts like the RHEL version, i.e. to do _Puppet classification_)

First of all this includes basic roles: Roles without any specific post-installation configuration, i.e. roles that don't install and configure applications that are supposed to offer a service managed by the Linux - or any other team. Essentially there are two possible use cases for this: 
1. A role that only prepares a server for use whitin the available infrastructure by wrapping a basic set of profiles together. Other roles will start with the same basic set of profiles. 
2. Servers without any specified purpose, e.g. like _"IAAS"_. Since there is no IAAS provisioning in the current service catalogue, nor are there people outside the infrastructure department with administrative privileges, in theory these systems can only be deployed for development purposes or for use as IAAS within the department.

Other roles maintained via this module include all servers under the sole responsability of the Linuxa administration. These includes 
* Linux monitoring server 
* custom solutions likee DNS fowrwarders, software based loadbalancers, ..).

### Setup Requirements 
To be able to checkout and push the code heer Git is needed. Next any text editor and a working knowledge of Puppet and Hiera data are required to be able to further develop this code. 

### Beginning with linux
Nice to haves are:
* an installation of the [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/latest/pdk.html) since that includes the Puppet agent, required to test your code
* an editor or IDE of choice, possible with extensions that provide functionality like using Git to commit your changes and use the Puppet agent to test your coude.

## Usage
Start with cloning this project. Further continue with your local Git configuration for this project (like project specific settings, `.gitignore` customisations, ..)

## Reference
See other README's and/or the project Wiki.

## Limitations
Profiles that are managing applications under the responsibility of other teams should be controled via another repository. Roles using these profiles are a shared responsibility of the Linux - and application administration team since they will usually contain profiles maintained by both teams. 

Code within this repository will only be tested with Red Hat Enterprise Linux (RHEL) 6 or later. Other operating stystems and versions are not managed using this code.

## Development
Members of the Linux administration team should contribute to this code to increase automation and improve quality of service.  

## Release Notes/Contributors/Etc. 
See Git commit histrory for canges and contributions. 
