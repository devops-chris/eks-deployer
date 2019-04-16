#!/bin/sh

if [ -z "$CLUSTER" ]; then
    echo "Please provide an Amazon EKS cluster name by populating the CLUSTER environment variable"
    echo "e.g."
    echo "docker run -e CLUSTER=mycluster devops-chris/kubectl get pods"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo "Please provide an Amazon EKS cluster name by populating the CLUSTER environment variable"
    echo "e.g."
    echo "docker run -e CLUSTER=mycluster -e REGION=us-east-1 devops-chris/kubectl get pods"
    exit 1
fi

# Write a ~/.kube/config file, using the AWS CLI to fetch the necessary parameters
mkdir -p ~/.kube
(cat > ~/.kube/config) <<EOF
apiVersion: v1
clusters:
- cluster:
    server: $(aws eks describe-cluster --name ${CLUSTER} --region ${REGION}| jq -r .cluster.endpoint) 
    certificate-authority-data: $(aws eks describe-cluster --name ${CLUSTER} --region ${REGION} | jq -r .cluster.certificateAuthority.data) 
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - ${CLUSTER}
EOF

# Pass through to kubectl
/bin/"$@"
