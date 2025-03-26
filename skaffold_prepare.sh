#!/bin/bash
set -e
set -o pipefail

EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-demo}"
EKS_NAMESPACE="${EKS_NAMESPACE:-demo}"
EKS_INGRESS_CLASS="${EKS_INGRESS_CLASS:-nginx}"
DEMO_SKAFFOLD_ENV_FILE="./skaffold.env"

check_tools() {
  echo "🔍 Checking required tools..."

  # Check Docker
  if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    exit 1
  fi

  # Check if Docker daemon is running
  if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "Please start the Docker service of your choice"
    exit 1
  fi

  # Check kubectl
  if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed or not in PATH"
    echo "kubectl can be installed with Homebrew"
    read -p "Would you like to install kubectl with brew? (y/n): " install_kubectl
    if [[ $install_kubectl == "y" || $install_kubectl == "Y" ]]; then
      brew install kubectl
    else
      echo "Please install kubectl from https://kubernetes.io/docs/tasks/tools/"
      exit 1
    fi
  fi

  # Check Helm
  if ! command -v helm &> /dev/null; then
    echo "❌ Error: Helm is not installed or not in PATH"
    echo "Helm can be installed with Homebrew"
    read -p "Would you like to install Helm with brew? (y/n): " install_helm
    if [[ $install_helm == "y" || $install_helm == "Y" ]]; then
      brew install helm
    else
      echo "Please install Helm from https://helm.sh/docs/intro/install/"
      exit 1
    fi
  fi

  # Check skaffold
  if ! command -v skaffold &> /dev/null; then
    echo "❌ Error: Skaffold is not installed or not in PATH"
    echo "Skaffold can be installed with Homebrew"
    read -p "Would you like to install Skaffold with brew? (y/n): " install_skaffold
    if [[ $install_skaffold == "y" || $install_skaffold == "Y" ]]; then
      brew install skaffold
    else
      echo "Please install Skaffold from https://skaffold.dev/docs/install/"
      exit 1
    fi
  fi

  # Check AWS CLI
  if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed or not in PATH"
    echo "AWS CLI can be installed with Homebrew"
    read -p "Would you like to install AWS CLI with brew? (y/n): " install_aws
    if [[ $install_aws == "y" || $install_aws == "Y" ]]; then
      brew install awscli
    else
      echo "Please install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
      exit 1
    fi
  fi

  echo "✅ All required tools are installed"
}

aws_setup() {
    echo "🔄 Checking AWS authentication..."
    # Check if AWS is authenticated
    if ! aws sts get-caller-identity &>/dev/null; then
        echo "❌ Error: Not authenticated with AWS"
        echo "Please set AWS credentials in your environment."
        echo "You need to set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and optionally AWS_SESSION_TOKEN."
        echo "For more information, see:"
        echo "https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html"
        exit 1
    else
        echo "✅ AWS authentication successful."
    fi

    # Check if AWS_REGION is set
    if [ -z "$AWS_REGION" ]; then
        echo "❌ Error: AWS_REGION is not set"
        echo "Please set AWS_REGION in your environment."
        echo "For example: export AWS_REGION=us-east-1"
        exit 1
    else
        echo "✅ AWS_REGION is set to $AWS_REGION"
    fi

    if [ -z "$ECR_REPO" ]; then
        echo "❌ Error: ECR_REPO is not set"
        echo "Please set ECR_REPO in your environment."
        exit 1
    fi

    # Substitute ECR_REPO in skaffold.yaml
    if [ -f "skaffold.yaml" ]; then
        sed -i.bak "s|<ECR_REPO>|$ECR_REPO|g" skaffold.yaml
        rm -f skaffold.yaml.bak
        echo "✅ ECR_REPO substituted in skaffold.yaml"
    else
        echo "❌ Error: skaffold.yaml not found"
        exit 1
    fi

    echo "🔄 Logging in to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
    echo "✅ ECR login successful"
}

k8s_setup() {
    echo "🔄 Updating Kubernetes context..."
    aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME &>/dev/null
    CURRENT_CONTEXT=$(kubectl config current-context)

    if ! kubectl get namespace $EKS_NAMESPACE &>/dev/null; then
        echo "🔄 Creating namespace $EKS_NAMESPACE..."
        kubectl create namespace $EKS_NAMESPACE
        echo "✅ Namespace $EKS_NAMESPACE created"
    else
        echo "✅ Namespace $EKS_NAMESPACE already exists"
    fi

    kubectl config set-context $CURRENT_CONTEXT --namespace=$EKS_NAMESPACE &>/dev/null
    echo "✅ Kubernetes context updated"
}

main() {
    start_time=$(date +%s)

    check_tools
    aws_setup
    k8s_setup

    export RELEASE=latest

    ENV_VARS=(
        "RELEASE"
        "ECR_REPO"
        "AWS_REGION"
        "EKS_CLUSTER_NAME"
        "EKS_NAMESPACE"
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
    )

    ENV_CONTENT=""
    for var in "${ENV_VARS[@]}"; do
        if [[ -n "${!var}" ]]; then
            ENV_CONTENT+="$var=${!var}\n"
        fi
    done

    echo -e "$ENV_CONTENT" > $DEMO_SKAFFOLD_ENV_FILE

    echo "✅ Environment variables exported to $DEMO_SKAFFOLD_ENV_FILE"

    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    echo "⏱️ skaffold_prepare execution time: ${execution_time} seconds"
}

main