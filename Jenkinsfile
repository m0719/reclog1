#!/usr/bin/env groovy

import java.text.SimpleDateFormat

final String branch = env.BRANCH_NAME


def buildEnv = [
    dockerLabel:        'Docker 18.09',
]

def registryMapping = [
  acr: [
    url: 'acrrectest.azurecr.io',
    credentialsId: 'acr_credentials_rectest'
  ],
  artifactory: [
    url: env.DOCKER_DEV_URL,
    credentialsId: 'jenkins-up'
  ]
]

pipeline {
  agent { 
      label 'slave' 
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 1, unit: 'HOURS')
  }

  parameters {
    booleanParam (
      defaultValue: true,
      description: 'Whether or not to publish the build image',
      name : 'PUSH_TO_REGISTRY'
    )
  }

  stages {
    stage('Init') {
      steps {
        script {
          echo "Initializing..."
          buildServer = "tcp://${env.DOCKER_BUILD_HOST}:2376"
          buildCredentialsId = env.DOCKER_BUILD_HOST.tokenize('.')[0]

          baseRegistryUrl = "https://${registryMapping.acr.url}"
          baseImageName = "rec/geoserver"
          tag = generateTag()
          dockerFile = "Dockerfile"

          echo "Logging environmental variables:"
          echo "Branch: ${branch}"
          echo "Base Image Name: ${baseImageName}"
          echo "Generated tag: ${tag}"
          echo "Docker Label: ${buildEnv['dockerLabel']}"
        }
      }
    }

    stage('Build docker image') {
      steps {
        script {
          docker.withTool(buildEnv['dockerLabel']) {
            docker.withServer(buildServer, buildCredentialsId) {
              echo "Building docker image..."

              // echo "Determining git commit hash"
              sh 'git rev-parse HEAD > commit'
              String commit = readFile('commit').trim()

              // Rewrite the Dockerfile so that our own registry is being used.
              sh("sed -i 's:FROM rec/:FROM ${registryMapping.acr.url}/rec/:' ${dockerFile}")

              echo "Building image..."
              docker.withRegistry("https://${registryMapping.acr.url}", registryMapping.acr.credentialsId) {
                buildImage = docker.build("${baseImageName}:${tag}", 
                  "--label gitCommit=${commit} "
                  + "--build-arg http_proxy=${env.HTTP_PROXY} "
                  + "--build-arg https_proxy=${env.HTTPS_PROXY} "
                  + "--build-arg no_proxy=${env.NO_PROXY} "
                  + "--no-cache "
                  + "-f ${dockerFile} "
                  + "./")
              }
            }
          }
        }
      }
    }

    stage('Push Container Registries') {
      when {
        expression { return params.PUSH_TO_REGISTRY }
      }
      steps {
        script {
          docker.withTool(buildEnv['dockerLabel']) {
            docker.withServer(buildServer, buildCredentialsId) {
              // Iterate over the registryMapping. Tags and pushes appropriatly
              registryMapping.each { name, registry ->
                docker.withRegistry("https://${registry.url}", registry.credentialsId) {
                  echo "Pushing image to: ${registry.url}"
                  sh "docker tag ${baseImageName}:${tag} ${registry.url}/${baseImageName}:${tag}"
                  sh "docker push ${registry.url}/${baseImageName}:${tag}"
                  
                  sh "docker tag ${baseImageName}:${tag} ${registry.url}/${baseImageName}:latest"
                  sh "docker push ${registry.url}/${baseImageName}:latest"
                }
              }
            }
          }
        }
      }
    }
  }

  post {
    success {
      script {
        currentBuild.description = "#${BUILD_NUMBER} - ${baseImageName}:${tag}"
      }
    }
  }
}

/**
 * Convenience function for generating an image tag. 
 *
 * e.g. 202002131524-master-33bebae
 */
private generateTag() {
  echo "Creating shortcommit-tag including date..."

  def dateFormat = new SimpleDateFormat("yyyyMMddHHmm")
  String date = dateFormat.format(new Date())

  String extratag = env.BRANCH_NAME == "master"?"master-":""

  String shortcommit = sh(
    script: "printf \$(git rev-parse --short ${GIT_COMMIT})",
    returnStdout: true
  )
  
  String tag = "${date}-${extratag}${shortcommit}"
  echo "tag is: ${tag}"

  return tag
}