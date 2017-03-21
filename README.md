# perlfox
A silly name for a silly browser package for people who need the Java plugin.

## What is this?
This is a simple Dockerfile for people who want to run the latest version of Firefox, but still need support for horrid applications that use NPAPI plugins (i.e. the dreaded Java plugin).

## How to use it
Simple, clone this repo. Then run the `start-container.sh` script to pull the image from Dockerhub, create the appropriate users, set permissions on the X11 socket and finally, run Firefox. If you would like to mount a special home directory for bookmarks, etc. that support will be added soon.
