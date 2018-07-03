# 拉取 CentOS
FROM centos:latest

# 维护者
MAINTAINER zscorpio.com <zsw.scorpio@gmail.com>

RUN curl --silent --location https://raw.githubusercontent.com/zscorpio/ss-tproxy/master/docker/install-ss-tproxy.sh  | bash - 
#ENTRYPOINT ss-tproxy restart
#RUN curl --silent --location http://dev.zscorpio.com/install-ss-tproxy.sh  | bash - 
#ENTRYPOINT ss-tproxy start
