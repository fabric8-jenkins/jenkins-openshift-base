FROM centos:centos7

# Jenkins image for OpenShift
#
# This image provides a Jenkins server, primarily intended for integration with
# OpenShift v3.
#
# Volumes:
# * /var/jenkins_home
# Environment:
# * $JENKINS_PASSWORD - Password for the Jenkins 'admin' user.

MAINTAINER Ben Parees <bparees@redhat.com>

# Jenkins LTS packages from
# https://pkg.jenkins.io/redhat-stable/
ENV JENKINS_VERSION=2.69 \
    HOME=/var/lib/jenkins \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_UC=https://updates.jenkins-ci.org

ENV EXPOSECONTROLLER_VERSION 2.3.27

LABEL k8s.io.description="Jenkins is a continuous integration server" \
      k8s.io.display-name="Jenkins 2.69" \
      openshift.io.expose-services="8080:http" \
      openshift.io.tags="jenkins,jenkins2,ci" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

# 8080 for main web interface, 50000 for slave agents
EXPOSE 8080 50000

RUN curl https://pkg.jenkins.io/redhat/jenkins.repo -o /etc/yum.repos.d/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat/jenkins-ci.org.key && \
    yum install -y centos-release-scl-rh && \
    INSTALL_PKGS="rsync gettext git tar zip unzip java-1.8.0-openjdk java-1.8.0-openjdk.i686 java-1.8.0-openjdk-devel java-1.8.0-openjdk-devel.i686 jenkins-2.69-1.1" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.UTF-8 && \
    set -o pipefail && curl -L https://github.com/openshift/origin/releases/download/v1.4.1/openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz | \
    tar -zx && \
    mv openshift*/oc /usr/local/bin && \
    rm -rf openshift-origin-client-tools-* && \
    curl -L https://github.com/fabric8io/exposecontroller/releases/download/v$EXPOSECONTROLLER_VERSION/exposecontroller-linux-amd64 > exposecontroller && \
    chmod +x exposecontroller && \
    mv exposecontroller /usr/bin/


# Google cloud stackdriver agent
RUN yum install -y wget && \
  mkdir /opt/cdbg && \
  wget -qO- https://storage.googleapis.com/cloud-debugger/compute-java/debian-wheezy/cdbg_java_agent_gce.tar.gz | \
  tar xvz -C /opt/cdbg

# Maven
RUN curl -L http://mirrors.ukfast.co.uk/sites/ftp.apache.org/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz | tar -C /opt -xzv

ENV M2_HOME /opt/apache-maven-3.3.9
ENV maven.home $M2_HOME
ENV M2 $M2_HOME/bin
ENV PATH $M2:$PATH

# nodejs
ENV NODE_VERSION 6.10.0
RUN yum install -y bzip2 fontconfig \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

COPY ./contrib/openshift /opt/openshift
COPY ./contrib/jenkins /usr/local/bin
ADD ./contrib/s2i /usr/libexec/s2i

RUN /usr/local/bin/install-plugins.sh /opt/openshift/base-plugins.txt && \
    # need to create <plugin>.pinned files when upgrading "core" plugins like credentials or subversion that are bundled with the jenkins server
    # Currently jenkins v2 does not embed any plugins, but for reference:
    # touch /opt/openshift/plugins/credentials.jpi.pinned && \
    rmdir /var/log/jenkins && \
    chmod 775 /etc/passwd && \
    chmod -R 775 /etc/alternatives && \
    chmod -R 775 /var/lib/alternatives && \
    chmod -R 775 /usr/lib/jvm && \
    chmod 775 /usr/bin && \
    chmod 775 /usr/lib/jvm-exports && \
    chmod 775 /usr/share/man/man1 && \
    unlink /usr/bin/java && \
    unlink /usr/bin/jjs && \
    unlink /usr/bin/keytool && \
    unlink /usr/bin/orbd && \
    unlink /usr/bin/pack200 && \
    unlink /usr/bin/policytool && \
    unlink /usr/bin/rmid && \
    unlink /usr/bin/rmiregistry && \
    unlink /usr/bin/servertool && \
    unlink /usr/bin/tnameserv && \
    unlink /usr/bin/unpack200 && \
    unlink /usr/lib/jvm-exports/jre && \
    unlink /usr/share/man/man1/java.1.gz && \
    unlink /usr/share/man/man1/jjs.1.gz && \
    unlink /usr/share/man/man1/keytool.1.gz && \
    unlink /usr/share/man/man1/orbd.1.gz && \
    unlink /usr/share/man/man1/pack200.1.gz && \
    unlink /usr/share/man/man1/policytool.1.gz && \
    unlink /usr/share/man/man1/rmid.1.gz && \
    unlink /usr/share/man/man1/rmiregistry.1.gz && \
    unlink /usr/share/man/man1/servertool.1.gz && \
    unlink /usr/share/man/man1/tnameserv.1.gz && \
    unlink /usr/share/man/man1/unpack200.1.gz && \
    chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    /usr/local/bin/fix-permissions /var/lib/jenkins && \
    /usr/local/bin/fix-permissions /var/log

VOLUME ["/var/lib/jenkins"]

USER 1001
CMD ["/usr/libexec/s2i/run"]
