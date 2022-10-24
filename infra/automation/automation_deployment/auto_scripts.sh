
#The below commands are used to get accesskey and secret key from the aws secret manager
echo checking for AWS credentials from Secret Manager
accesskey=$(aws secretsmanager get-secret-value --secret-id 'automation_access_key' --query 'SecretString' --output text | jq -r '.automation_id')
secretkey=$(aws secretsmanager get-secret-value --secret-id 'automation_access_key' --query 'SecretString' --output text | jq -r '.automation_access_key')

#The received aws credentials are configured inside the custom image 
echo Aws credentials retrieved from secret manager.......
aws configure set aws_access_key_id $accesskey; aws configure set aws_secret_access_key $secretkey; aws configure set default.region "us-east-1"; aws configure set default.format "json"
echo AWS credentials configured Successfully $app $clustername $role

#command used to login to cluster
echo logging in to cluster
aws eks --region us-east-1 update-kubeconfig --name $clustername

#command used to find the current image running inside the pod
oldimage=$(kubectl describe deployment $app -n actimize | grep Image)
echo Current running $app:$oldimage

#command used to check latest image in application repository
echo Checking for latest image at ECR Repository
repo=556277294023.dkr.ecr.us-east-1.amazonaws.com/actimize-$role-$app
tag=$(aws ecr describe-images --repository-name actimize-$role-$app --output text --query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' | tr '\t' '\n' | tail -1)

#command used to push the repo and tag values to deployment files
echo The Latest image going to be deployed in $app:$tag
sed -i 's@alpha@'"$tag"'@' ./infra/automation/deployment/environment/$role/$app/kustomization.yaml

#command to initiate the deployment in kubernet Pods
echo Deployment has been initiated........
kubectl apply -k ./infra/automation/deployment/environment/$role/$app

#command to check the deployment status
echo Please find the deployment status
kubectl rollout status deployment/$app -n actimize

#command used to check the Pod status post deployment 
echo Please find below the $app pod status....
sleep 60
kubectl get pods -n actimize  | grep $app-

#command to remove AWS credentials from custom image
cd ~/.aws
rm -f /root/.aws/credentials
echo Listing aws folder to confirm aws credentials has been removed from the custom Image...
ls /root/.aws

