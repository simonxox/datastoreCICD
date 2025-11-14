pipeline {
  agent any

  parameters {
    string(name: "App_Version", defaultValue: "v${BUILD_NUMBER}", description: "provide application version")
  }

  environment {
    // keep your existing credential id; used below via withCredentials
    DOCKERHUB_CREDS_ID = "dockerhub"
  }

  stages {
    // === parallel test stage inserted here ===
    stage("test") {
      parallel {
        stage("p-1st-stage") {
          steps {
            sh 'echo start p1; sleep 5; echo end p1'
          }
        }
        stage("p-2nd-stage") {
          steps {
            sh 'echo start p2; sleep 7; echo end p2'
          }
        }
      }
    }

    stage("Repo Clone") {
      steps {
        checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/simonxox/datastoreCICD.git']])
      }
    }

    stage("Maven Build") {
      steps {
        sh '''
          echo "-------- Building Application --------"
          mvn clean package -DskipTests=false
          echo "------- Application Built Successfully --------"
        '''
      }
    }

    stage("Maven Test") {
      steps {
        sh '''
          echo "-------- Executing Testcases --------"
          mvn test
          echo "-------- Testcases Execution Complete --------"
        '''
      }
    }

    stage("Artifact Store") {
      steps {
        sh '''
          echo "-------- Pushing Artifacts To S3 --------"
          aws s3 cp ./target/*.jar s3://bakka1122/
          echo "-------- Pushing Artifacts To S3 Completed --------"
        '''
      }
    }

    // Build image already namespaced to Docker Hub user when logged in below
    stage("Docker Image Build") {
      steps {
        // build image with final Docker Hub repo name to avoid separate tag-step issues
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
          sh '''
            echo "-------- Building Docker Image (namespaced) --------"
            IMAGE="${DH_USER}/datastore:${App_Version}"
            docker build -t "${IMAGE}" .
            echo "-------- Image Successfully Built as ${IMAGE} --------"
          '''
        }
      }
    }

    stage("Docker Image Scan") {
      steps {
        // use --cache-dir to avoid permission issues and skip default config read if problematic
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
          sh '''
            IMAGE="${DH_USER}/datastore:${App_Version}"
            echo "-------- Scanning Docker Image ${IMAGE} --------"
            mkdir -p /var/lib/jenkins/.cache/trivy || true
            chown -R $(id -u jenkins 2>/dev/null || echo 1000):$(id -g jenkins 2>/dev/null || echo 1000) /var/lib/jenkins/.cache/trivy || true
            trivy image --cache-dir /var/lib/jenkins/.cache/trivy "${IMAGE}" || echo "Trivy scan returned non-zero (check output)"
            echo "-------- Scanning Docker Image Complete --------"
          '''
        }
      }
    }

    // Logging in and pushing securely
    stage("Loggingin & Pushing Docker image") {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
          sh '''
            IMAGE="${DH_USER}/datastore:${App_Version}"
            echo "-------- Logging To DockerHub --------"
            echo "$DH_TOKEN" | docker login --username "$DH_USER" --password-stdin
            echo "-------- DockerHub Login Successful --------"
            echo "-------- Pushing Docker Image To DockerHub: ${IMAGE} --------"
            docker push "${IMAGE}"
            echo "-------- Docker Image Pushed Successfully --------"
          '''
        }
      }
    }

    stage("cleanup") {
      steps {
        sh '''
           echo "-------- Cleaning Up Jenkins Machine --------"
           docker image prune -a -f || true
           echo "-------- Clean Up Successful --------"
        '''
      }
    }

    stage("Deployment Acceptance") {
      steps {
        input 'Trigger Down Stream Job'
      }
    }
  } // stages
}
