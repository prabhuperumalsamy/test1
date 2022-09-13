#The below commands are used to get accesskey and secret key from the aws secret manager
echo Checking for AWS credentials from Secret Manager.....
accesskey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efileraccesskey')
secretkey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efilersecretkey')

#The received aws credentials are configured inside the custom image 
aws configure set aws_access_key_id $accesskey; aws configure set aws_secret_access_key $secretkey; aws configure set default.region "us-east-1"; aws configure set default.format "json"
echo AWS credentials configured inside custom image Successfully


#Fecthing user inputs from manual_deployment_parameters.yaml file and proceeding for deployment
echo Checking for user inputs from mamaul_deployment_parameters.yaml file
tag=$(grep -w "deployment_tag" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
tag1=$(grep -w "deployment_tag" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
env=$(grep -w "environment" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
app=$(grep -w "application" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
cluster=$(grep -w "cluster" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
repo=556277294023.dkr.ecr.us-east-1.amazonaws.com/actimize-$env-$app

#checking user inputs with ECR Registry
#!/bin/bash
ecrtag=$(aws ecr describe-images --repository-name=actimize-$env-$app  --image-ids=imageTag=$tag | jq '.imageDetails[0].imageTags[0]' -r)
if [ "$ecrtag" = "$tag1" ]; then
sed -i 's@apache:apache@'"$repo:$ecrtag"'@' ./yamlfiles/$app.yaml
echo The given Image tag found in ECR Repository;
else
echo Please check the provided inputs are valid
echo Image tag:$tag
echo environment:$env
echo application:$app
echo cluster:$cluster
exit 1;
fi

#Command used to find the current image running inside the pod
oldimage=$(kubectl describe deployment $app -n actimize | grep Image)
echo Current running $app $oldimage

#Command used to display the image details which we are going to deploy
echo ---------------------------------------------------------------------------------------
echo latest image going to deploy $tag and image retrived from $repo


#logging into the cluster
echo logging in to cluster
aws eks --region us-east-1 update-kubeconfig --name $cluster

#command to inititate the deployment
echo Deployment has been initiated........
kubectl apply -f ./yamlfiles/$app.yaml -n actimize
echo ---------------------------------------------------------------------------------------

#command used to check the Pod status post deployment 
echo Please find below the $app pod status....
sleep 60
kubectl get pods -n actimize  | grep $app

#command used to delete the stored aws credentials from the custom image
cd ~/.aws
rm -f /root/.aws/credentials
echo Listing aws folder to confirm aws credentials has been removed from the custom Image...
ls /root/.aws
