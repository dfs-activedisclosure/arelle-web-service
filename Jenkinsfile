#!/usr/bin/groovy

// load pipeline functions
// Requires pipeline-github-lib plugin to load library from github
@Library('github.com/campbelldgunn/jenkins-pipeline@master')
def pipeline = new org.whiteshieldinc.Pipeline()

podTemplate(label: 'jenkins-pipeline', nodeSelector: 'os=linux', containers: [
    containerTemplate(name: 'jnlp', image: 'jenkinsci/jnlp-slave:3.14-1-alpine', args: '${computer.jnlpmac} ${computer.name}', workingDir: '/home/jenkins', resourceRequestCpu: '100m', resourceLimitCpu: '400m', resourceRequestMemory: '128Mi', resourceLimitMemory: '768Mi'),
    containerTemplate(name: 'docker', image: 'docker:1.12.6', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'campbelldgunn/k8s-helm:v2.8.1', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'kubectl', image: 'campbelldgunn/k8s-kubectl:v1.9.3', command: 'cat', ttyEnabled: true)
],
volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
]){

  node ('jenkins-pipeline') {

    def pwd = pwd()

    checkout scm

    def chart_dir = "${pwd}/charts/arelle-web-service"
    def inputFile = readFile('Jenkinsfile.json')
    def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
    println "pipeline config ==> ${config}"

    if (!config.pipeline.enabled) {
        println "pipeline disabled"
        return
    }

    pipeline.gitEnvVars()

    def acct = pipeline.getContainerRepoAcct(config)
    def tags = pipeline.getContainerTags(config)

    stage ('build container') {
      container('docker') {

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: config.container_repo.jenkins_creds_id,
                        usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
          sh "docker login -u ${env.USERNAME} -p ${env.PASSWORD} dfsacr.azurecr.io"
        }

        pipeline.containerBuildPub(
            dockerfile: config.container_repo.dockerfile,
            host      : config.container_repo.host,
            acct      : acct,
            repo      : config.container_repo.repo,
            tags      : tags,
            auth_id   : config.container_repo.jenkins_creds_id
        )
      }
    }

    stage ('validate helm') {
      container('helm') {
        pipeline.helmLint(chart_dir)
      }
    }

    def Boolean smoke_test = env.BRANCH_NAME != 'master'
    def String deploy_stage_name = smoke_test ? 'validate deployment' : 'deploy'

    stage (deploy_stage_name) {
      container('helm') {
        def Boolean bad_things = false
        def String name = config.app.name
        def String namespace = config.app.namespace
        def Integer replicas = config.app.replicas
        def String hostname = config.app.hostname

        // Smoke Test Deployment
        if (smoke_test == true) {
          def commit = env.GIT_COMMIT_ID.substring(0, 7)
          name = "sha-${commit}-${config.app.name}"
          hostname = "sha-${commit}-${config.app.hostname}"
          replicas = 1

          pipeline.helmDeploy(
            dry_run       : false,
            name          : name,
            namespace     : namespace,
            version_tag   : tags.get(0),
            chart_dir     : chart_dir,
            replicas      : replicas,
            cpu           : config.app.cpu,
            memory        : config.app.memory,
            hostname      : hostname
          )
          // Provide enough time to send details to Jenkins log.
          sleep 240

          pipeline.helmTest(
            name        : name
          )

          sh "helm status ${name}"

          pipeline.helmDelete(
            name        : name
          )
        }

        if (smoke_test == false) {

          // Deploy using Helm chart to Production.
          pipeline.helmDeploy(
            dry_run       : false,
            name          : name,
            namespace     : namespace,
            version_tag   : tags.get(0),
            chart_dir     : chart_dir,
            replicas      : config.app.replicas,
            cpu           : config.app.cpu,
            memory        : config.app.memory,
            hostname      : hostname
          )

          sh "helm status ${name}"
        }
      }
    }
  }
}