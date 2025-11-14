pipeline {
  agent any

  parameters {
    string(name: "App_Version", defaultValue: "v1", description: "application version")
    string(name: "DOCKER_NAMESPACE", defaultValue: "8072388539", description: "Docker Hub username/org")
  }

  environment {
    DOCKER_IMAGE = "${params.DOCKER_NAMESPACE}/datastore:${params.App_Version}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/main']],
          userRemoteConfigs: [[url: 'https://github.com/simonxox/datastoreCICD.git']]])
      }
    }

    stage('Maven Build & Test') {
      agent {
        docker {
          image 'maven:3.9.4-eclipse-temurin-17'
          args '-v $HOME/.m2:/root/.m2'
        }
      }
      steps {
        sh 'mvn -v'
        sh 'mvn -B clean package'
      }
    }

    stage('Upload artifact to S3') {
      steps {
        // uses amazon/aws-cli container (instance role recommended)
        sh '''
          docker run --rm -v $PWD:/workdir -w /workdir amazon/aws-cli:2.16.23 \
            s3 cp ./target/*.jar s3://bakka1122/ || true
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          echo "Building ${DOCKER_IMAGE}"
          docker build -t ${DOCKER_IMAGE} .
          docker images ${DOCKER_IMAGE} || true
        '''
      }
    }

    stage('Image Scan') {
      steps {
        sh '''
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest \
            image --timeout 5m ${DOCKER_IMAGE} || true
        '''
      }
    }

    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push ${DOCKER_IMAGE}
            docker logout
          '''
        }
      }
    }

    stage('Cleanup') {
      steps {
        sh 'docker image prune -a -f || true'
      }
    }

    stage('Deployment Acceptance') {
      steps {
        input message: "Trigger downstream deploy?"
      }
    }
  }

  post {
    always { echo "Pipeline finished." }
    failure { echo "Pipeline failed." }
  }
}
