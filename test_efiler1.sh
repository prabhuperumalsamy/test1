echo checking for AWS credentials from Secret Manager
accesskey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efileraccesskey')
secretkey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efilersecretkey')

echo Aws credentials retrieved from secret manager.......
aws configure set aws_access_key_id $accesskey; aws configure set aws_secret_access_key $secretkey; aws configure set default.region "us-east-1"; aws configure set default.format "json"
echo AWS credentials configured Successfully

echo Checking for repo at ECR
repo=556277294023.dkr.ecr.us-east-1.amazonaws.com/actimize-test-efiler
tag=$(aws ecr describe-images --repository-name actimize-test-efiler --output text --query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' | tr '\t' '\n' | tail -1)
echo $tag
sed -i 's@apache:apache@'"$repo:$tag"'@' ./efiler.yaml

echo logging in to cluster
aws eks --region us-east-1 update-kubeconfig --name test-actimize-eksCluster-0da6128

echo Deployment has been initiated........
kubectl apply -f ./efiler.yaml -n actimize

cd ~/.aws
rm -f /root/.aws/credentials
echo Listing aws folder to confirm aws credentials has been removed from the custom Image...
ls /root/.aws
