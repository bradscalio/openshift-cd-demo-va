QUAY_USER=
QUAY_PWD=
skopeo copy docker://docker.io/siamaksade/jenkins-slave-skopeo-centos7:latest docker://quay.io/gbengataylor/jenkins-slave-skopeo-centos7:latest --dest-creds $QUAY_USER:$QUAY_PWD --src-tls-verify=false --dest-tls-verify=false
# already a quay image at quay.io/siamaksade/gogs
#skopeo copy docker://docker.io/openshiftdemos/gogs:0.11.34 docker://quay.io/gbengataylor/gogs:0.11.34
skopeo copy docker://docker.io/siamaksade/sonarqube:latest docker://quay.io/gbengataylor/sonarqube:latest --dest-creds $QUAY_USER:$QUAY_PWD --src-tls-verify=false --dest-tls-verify=false
skopeo copy docker://docker.io/sonatype/nexus3:3.13.0 docker://quay.io/gbengataylor/nexus3:3.13.0 --dest-creds $QUAY_USER:$QUAY_PWD --src-tls-verify=false --dest-tls-verify=false


# or docker (docker login to quay first)
docker pull docker.io/siamaksade/sonarqube
docker tag docker.io/siamaksade/sonarqube quay.io/gbengataylor/sonarqube 
docker push quay.io/gbengataylor/sonarqube 

docker pull docker.io/sonatype/nexus3
docker tag docker.io/sonatype/nexus3 quay.io/gbengataylor/nexus3 
docker push quay.io/gbengataylor/nexus3 