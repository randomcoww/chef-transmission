FROM phusion/baseimage:latest
RUN apt-get update
RUN apt-get install -y build-essential ruby1.9.3
ADD phusion.key.pub /root/.ssh/authorized_keys
