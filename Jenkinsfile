/*
 SPDX-FileCopyrightText: © 2025 Clifford Weinmann <https://www.cliffordweinmann.com/>
 SPDX-License-Identifier: MIT-0

 Example Jenkins pipeline that uses "make" & "docker" in our own agent container image
 Requires the Docker Pipeline plugin
 Not currently in use
 Last tested with v1.9.0 - 2025-11-19

 This pipeline requires 2 credentials, namely:
 - A credential for pulling the code from our git repo
 - A credential called "docker" for accessing Docker Hub
 */

pipeline {

	agent {
		dockerfile {
			filename 'Dockerfile.jenkins'
			dir 'build'
		}
	}

	environment {
		/* Container registry */
		REGISTRY_NAME = "docker.io"
		/* Jenkins credential for authenticating to registry */
		REGISTRY_CREDENTIAL = "docker"
		/* Image base name */
		REPOBASE	  = "docker.io/cliffordw"
	}

	stages {
		stage('build') {
			steps {
				sh 'make CONTAINER_ENGINE=docker REPOBASE=${REPOBASE} build-release'
				sh 'make CONTAINER_ENGINE=docker REPOBASE=${REPOBASE} test-release'
			}
		}
		stage('push') {
			steps {
				withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIAL}", usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASSWORD')]) {
					sh('docker login --username ${REGISTRY_USER} --password ${REGISTRY_PASSWORD} ${REGISTRY_NAME}')
					sh('make CONTAINER_ENGINE=docker REPOBASE=${REPOBASE} push-release')
				}
			}
		}
	}

	post {
		always {
			sh('docker logout ${REGISTRY_NAME}')
		}
	}
}
