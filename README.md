# Demo for skaffold usage with Helm

This repository contains a demo application and supporting scripts to showcase how to use Skaffold together with Helm for continuous development in a Kubernetes environment. The demo is designed for learning purposes and is suitable for workshops, tutorials, or personal experimentation.


See https://skaffold.dev/docs/ for Skaffold documentation.

Meetup ref: https://www.meetup.com/barcelona-sre-community/events/306569688/

## Prerequisites

Before you begin, ensure you have the following:

* **Amazon EKS Cluster**: A running EKS cluster
* **Amazon ECR Repository**: A configured ECR repository for storing Docker images.
* **Helm**: Installed and configured to interact with your Kubernetes cluster.
* **Skaffold**: Installed on your machine. You can follow [Skaffold's installation guide](https://skaffold.dev/docs/install/).
* **Docker**: To build image
* **Docker Compose**: To run the application locally
* **Make Utility**: Ensure you have make installed to use the provided Makefile.
* **Environment Variables**: Set the following environment variables:
  * `AWS_REGION`
  * `AWS_ACCESS_KEY_ID`
  * `AWS_SECRET_ACCESS_KEY`
  * `ECR_REPO`
  * `EKS_CLUSTER_NAME` (optional, default=demo)
  * `EKS_NAMESPACE` (optional, default=demo)
  * `EKS_INGRESS_CLASS` (optional, default=nginx)


## Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/apologist/sre-meetup-6th-demo.git
   cd sre-meetup-6th-demo
   ```

2. **Set Up Environment Variables:**

Export the required environment variables in your shell:


```bash
export AWS_REGION=your-region
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret
export ECR_REPO=your-ecr-repo
export EKS_CLUSTER_NAME=your-eks-cluster
```

## Usage

The project includes a Makefile with commands to streamline development and deployment workflows:

### Environment Preparation

```bash
make skaffold_prep
```
Runs the skaffold_prepare.sh script to set up your environment variables and authenticate with AWS services. 

### Building the Application

```bash
make build
```
Prepares the environment and builds the Docker image using Skaffold with the demo profile. The image will be pushed to your configured ECR repository.

### Development Mode

```bash
make dev
```
Runs Skaffold in development mode with the demo profile. This sets up a continuous development workflow where:
- Changes to your code trigger automatic rebuilds
- The container is updated with the new image
- You can see logs and outputs in real-time

### Deployment

```bash
make run
```
Builds the application and deploys it to your Kubernetes cluster using the Helm chart. This command:
1. Builds and pushes the Docker image
2. Deploys the Helm chart to your configured EKS cluster
3. Sets up the necessary Kubernetes resources (Deployment, Service, etc.)

### Rendering Kubernetes Manifests

```bash
make render
```
Generates and displays the Kubernetes manifests that would be applied without actually deploying them. This is useful for:
- Reviewing the configuration before deployment
- Debugging issues with Kubernetes resources
- Understanding what Skaffold and Helm will create

### Local Development

To run the demo application locally using Docker Compose:

```bash
docker-compose up
```

This will start the application on http://localhost:8000.

## Application Structure

- **Docker**: The application is containerized using Docker
- **Helm**: Kubernetes deployment is managed through Helm charts in the `helm/` directory
- **Skaffold**: Configuration in `skaffold.yaml` enables continuous development

## Kubernetes Resources

When deployed, the application creates the following Kubernetes resources:
- **Deployment**: Manages the application pods
- **Service**: ClusterIP service for internal communication 
- **Ingress**: Exposes the application to external traffic
- **ConfigMap**: Stores environment variables and configuration
