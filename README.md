# Complete HashiCorp stack for development

This is a personal learning project to learn how to use the tech stack built by [HashiCorp](https://www.hashicorp.com/).


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
