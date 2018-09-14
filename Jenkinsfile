#!/usr/bin/groovy
// See scripts in .cico/ directory as this will be moved soon,
@Library('github.com/fabric8io/fabric8-pipeline-library@master')
def name = 'jenkins-openshift-base'
def org = 'fabric8io'
dockerTemplate{
    s2iNode(s2iImage: 'fabric8/s2i-builder:0.0.3'){
        checkout scm
        if (env.BRANCH_NAME.startsWith('PR-')) {
            echo 'Running CI pipeline'
            container('s2i') {
                sh 'make build VERSION=2'
                sh 'make build VERSION=slave-base'
            }

            def newVersion = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
            stage ('push to dockerhub'){
                container('docker') {
                    sh "docker tag openshift/jenkins-2-centos7:latest fabric8/jenkins-openshift-base:${newVersion}"
                    sh "docker push fabric8/jenkins-openshift-base:${newVersion}"
                }
            }

        } else if (env.BRANCH_NAME.equals('master')) {
            echo 'Running CD pipeline'
            def newVersion = getNewVersion {}

            stage ('build'){
                container('s2i') {
                    sh 'make build VERSION=2'
                    sh 'make build VERSION=slave-base'
                }
            }

            stage ('push to dockerhub'){
                container('docker') {
                    sh "docker tag openshift/jenkins-2-centos7:latest fabric8/jenkins-openshift-base:${newVersion}"
                    sh "docker tag openshift/jenkins-slave-base-centos7:latest fabric8/jenkins-slave-base-centos7:${newVersion}"

                    sh "docker push fabric8/jenkins-openshift-base:${newVersion}"
                    sh "docker push fabric8/jenkins-slave-base-centos7:${newVersion}"
                }
            }
            updateDownstreamRepos(newVersion)
        }
    }
}

def updateDownstreamRepos(newVersion){
    container('s2i') {

        def flow = new io.fabric8.Fabric8Commands()
        flow.setupGitSSH()

        def uid = UUID.randomUUID().toString()
        def branch = "versionUpdate${uid}"
        def message = "Update jenkins base image to ${newVersion}"

        sh """
           git clone git@github.com:fabric8io/openshift-jenkins-s2i-config.git --depth 1
           cd openshift-jenkins-s2i-config
           git checkout -b ${branch}
           sed -i 's/baseImageVerion = .*/baseImageVerion = \"${newVersion}\"/g' Jenkinsfile
           git commit Jenkinsfile -m "${message}"
           git push origin ${branch}
           """

        def prId = flow.createPullRequest(message, 'fabric8io/openshift-jenkins-s2i-config', branch)
        //flow.mergePR(gitRepo, prId)
    }
}
