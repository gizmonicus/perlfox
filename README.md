# perlfox
A silly name for a silly browser package for people who need the Java plugin. Why perlfox when none of the code is written in Perl? It's an inside joke I use to describe any workaround developed to fix an ugly or otherwise unusable interface or application.

## What is this?
This is a simple Dockerfile for people who want to run the latest version of Firefox, but still need support for horrid applications that use NPAPI plugins (i.e. the dreaded Java plugin). This image uses X11 forwarding over SSH because this works with older X11 systems as well as the newer Wayland systems that don't have the same X11 socket in /tmp.

## How to use it
Simple, clone this repo. Then run the `start-container.sh` script. Use `start-container.sh -h` for DNS options. This script will do all the necessary steps to start the container and allow your user to SSH into it. The script does the following automatically:
* Creates ~/.perlfox_home
* Creates a temporary SSH keypair and stores it under ~/.ssh
* Pulls and runs the docker container
* Exports your UID/GID to the container to set the correct permissions
* SSH into container with your newly created keypair.

After you exit the container, the script removes all temporary files, but leaves the ~/.perlfox_home directory in place so you can save your preferences, etc.
