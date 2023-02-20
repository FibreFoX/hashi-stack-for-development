# HashiCorp stack for development

This is a personal learning project to learn how to use the tech stack built by [HashiCorp](https://www.hashicorp.com/). THIS IS **STILL WORK AND CONCEPT IN PROGRESS**!


## Motivation
In the early days all it needed to make a new service available was by placing the proper WAR-file in a known location for the Servlet-Engine like JBoss or Tomcat.  
Then Linux containers came to light to minimize the unused potential of hardware systems, less wasted "idle-cycles" of the server and less "application fighting each other".

Now we are going towards distributed systems, not knowing where exactly out stuff is running, as long as it is reachable somehow.

Kubernetes was not the first "big thing" but one of the loudest (probably due to Google became a monopoly for its kind) and is still know for its YAML-hell.

I DO NOT LIKE Kubernetes, I actually dislike it! A LOT! ... Ever tried to create a production-ready SELF HOSTED (aka on-premise) cluster? Feeled the need to use Rancher just to have the illusion to "control" anything there? Or are you getting confused about all the YAML-files distributed in your sofware-repository?

No, this is not for me!

## Some history

Some years ago I started to use that one nice tool that makes me create a local VM using funny looking text files, having all steps to create the system automated and therefor documented. If was fun and I even started to use it in my personal projects.  
Now with more years of experience from different perspectives (frontend software developer, backend software developer, systems administrator, emergency hotline, go-to-guy for problems, ...), I am sick of a lot of concepts and especially to be too dependant on "big corps" to provide me with their services. This is **from a non-financial perspective**! The business decisions to depend on external personal and knowledge (the "cloud providers") has so many pitfalls, e.g. being **dependant** on the provider to acutal deliver, forced to pay more to still be online ... not the first time prices got increased.

## The alternative world

My hashi stack includes the following:

* [Packer](https://www.packer.io/) to create the VM image for vagrant (sometimes called as "golden image", comes from the music industry)
* [Vagrant](https://www.vagrantup.com/) to create a local VM setup
* [Terraform](https://www.terraform.io/) for managing infrastructure as code (IaC)
* [Nomad](https://www.nomadproject.io/) to deploy the applications "in the cloud"
* [Consul](https://www.consul.io/) for service mesh including service catalogue for traefik (oops, spoiler-alert)
* [Vault](https://www.vaultproject.io/) for storing secrets and doing secrets stuff

In addition to learn other tools, it does include these parts:

* [Proxmox Virtual Environment](https://proxmox.com/en/proxmox-ve) for having a cluster-able server manager that makes HA available (and as a reason to learn Terraform)
* [Docker](https://www.docker.com/) as popular container deployment system
* [GitLab CI-server](https://about.gitlab.com/) for testing your build pipeline code before pushing broken instructions to the git repository, pushed to a git repository (insert inception joke here)
* [Traefik](https://traefik.io/traefik/) for routing requests "on the edge"
* [Step-CA](https://smallstep.com/certificates/) as a local certificate authority (CA) that supports the ACME protocol

# How it all works

These are a lot of technologies that fit several parts of a whole development project. They are not trivial, and there probably are even more possible, but they are sufficient to make a "complete tour through development and deployment".

## Development infrastructure

```plantuml
@startuml
!include C4_Container.puml

LAYOUT_TOP_DOWN()
LAYOUT_WITH_LEGEND()

title HashiCorp stack for (local) development infrastructure

Person(you, You, "The developer using this project")
@enduml
```

## How to use

As the whole system is quite complex, because I wanted to mix all components which can be projected to a bigger scale.

### Step 0 - Prepare your local dev system

As I am using Windows as my daily driver, I need several things being configured and installed first. To manage most of the tools, I am using [Chocolatey](https://chocolatey.org/).

```ps
# TODO add steps to activate HyperV
choco install consul docker-desktop nomad packer vagrant
```

Of course a restart is required (mostly due to Vagrant).

### Step 1 - Build the Proxmox VE base image (using Packer and Vagrant)

As the ProxmoxVE VM is getting created via Vagrant, it would be a waste of time to always recreate the whole VM, so we create an image first via Packer:
```sh
# change to folder with build file
cd .dev/proxmox
# to build the Vagrant box image
packer build .
```

You should get greeted with something like this:
```
==> hashi-stack-proxmox.vagrant.debainbase: Creating a Vagrantfile in the build directory...
==> hashi-stack-proxmox.vagrant.debainbase: Adding box using vagrant box add ...
    hashi-stack-proxmox.vagrant.debainbase: (this can take some time if we need to download the box)
==> hashi-stack-proxmox.vagrant.debainbase: Calling Vagrant Up (this can take some time)...
...
... (this REALLY can take a long time, around 15 - 20 minutes, including several reboots of the VM)
...
==> hashi-stack-proxmox.vagrant.debainbase: Downloading /tmp/debian_lxc_image => debian_lxc_image
==> hashi-stack-proxmox.vagrant.debainbase: Packaging box...
```

This should create a vagrant box file around 2.8 GB in size. In addition to that a file called `debian_lxc_image` is created which contains the actual downloaded LXC image filename, which will be used later. So no guesswork needed, as this might change with time.

After the creating the box image, import it and create the VM using Vagrant:

```ps
vagrant box add --force proxmox ./proxmox-image/package.box
vagrant up --provision
```
