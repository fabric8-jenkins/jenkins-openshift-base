#!/bin/bash
#
# Build script for CI builds on CentOS CI

set -ex

function setup() {
    if [ -f jenkins-env.json ]; then
        eval "$(./env-toolkit load -f jenkins-env.json \
        JENKINS_URL GIT_BRANCH GIT_COMMIT BUILD_NUMBER ghprbSourceBranch \
        ghprbActualCommit BUILD_URL ghprbPullId)"
    fi

    # We need to disable selinux for now, XXX
    /usr/sbin/setenforce 0 || :

    yum -y install docker make golang git
    service docker start

    echo 'CICO: Build environment created.'
}

function build_push_images() {
    make build VERSION=2
    make build VERSION=slave-base

    newVersion="${GIT_BRANCH}-${BUILD_NUMBER}"
    docker tag openshift/jenkins-2-centos7:latest \
           fabric8/jenkins-openshift-base:${newVersion}
    docker push fabric8/jenkins-openshift-base:${newVersion}
}
