The following diagram shows the steps included in the deployment pipeline:

![](images/pipeline.svg)

*NOTE*: Quay.io isn't an option
If you want to use Quay.io as an external registry with this demo, Go to quay.io and register for free. Then deploy the demo providing your 
quay.io credentials:

  ```
 /scripts/provision.sh deploy --private --enable-quay --quay-username quay_username --quay-password quay_password
  ```
In that case, the pipeline would create an image repository called `tasks-app` (default name but configurable) 
on your Quay.io account and use that instead of the integrated OpenShift 
registry, for pushing the built images and also pulling images for deployment. 

## Demo Guide


* If you have enabled Quay, after image build completes go to quay.io and show that a image repository is created and contains the Tasks app image

![](images/quay-pushed.png?raw=true)



* After pipeline completion, demonstrate the following:
  * Explore the _snapshots_ repository in Nexus and verify _openshift-tasks_ is pushed to the repository
  * Explore SonarQube and show the metrics, stats, code coverage, etc
  * Explore _Tasks - Dev_ project in OpenShift console and verify the application is deployed in the DEV environment
  * Explore _Tasks - Stage_ project in OpenShift console and verify the application is deployed in the STAGE environment  
  * If Quay enabled, click on the image tag in quay.io and show the security scannig results 

![](images/sonarqube-analysis.png?raw=true)

![](images/quay-claire.png?raw=true)
