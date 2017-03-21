FROM centos:6
RUN yum -y clean all
RUN yum -y update && \
    yum -y install firefox java icedtea-web.x86_64 && \
    yum -y clean all
ADD ./run.sh /usr/local/bin/run.sh
CMD ["/usr/local/bin/run.sh"]
