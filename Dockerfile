FROM centos:6
RUN yum -y install firefox java icedtea-web.x86_64
ADD ./run.sh /usr/local/bin/run.sh
CMD ["/usr/local/bin/run.sh"]
