# Deploying a 2-tier application on Minikube
- [Deploying a 2-tier application on Minikube](#deploying-a-2-tier-application-on-minikube)
  - [Objectives:](#objectives)
  - [Provisioning Script for Kubernetes Metrics Server and Application Deployment](#provisioning-script-for-kubernetes-metrics-server-and-application-deployment)
    - [Step 1: Apply Metrics Server Components](#step-1-apply-metrics-server-components)
    - [Step 2: Patch the Metrics Server Deployment](#step-2-patch-the-metrics-server-deployment)
    - [Step 3: Restart the Metrics Server Deployment](#step-3-restart-the-metrics-server-deployment)
    - [Step 4: Apply Application Deployment](#step-4-apply-application-deployment)
    - [Step 5: Display All Resources](#step-5-display-all-resources)

## Objectives:

- Deploy containerised 2-tier deployment (app and database) on a single VM using Minikube
- Database should use a PV of 100 MB
- Use HPA to scale the app, min 2, max 10 replicas - load test to check it works
- Use NodePort service and Nginx reverse proxy to expose the app service to port 80 of the instance's public IP
- Make sure that minikube start happens automatically on re-start of the instance

## Provisioning Script for Kubernetes Metrics Server and Application Deployment

This script uses Minikube’s `kubectl` command to provision and configure the Kubernetes Metrics Server, then deploys an application using a specified YAML file.

### Step 1: Apply Metrics Server Components

```bash
minikube kubectl -- apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

- **Explanation**: Downloads and applies the YAML manifest for the Kubernetes Metrics Server from the official repository. The Metrics Server is a cluster add-on that collects resource usage data, such as CPU and memory, from nodes and pods, making it available for tools like `kubectl top`.

### Step 2: Patch the Metrics Server Deployment

```bash
minikube kubectl -- patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'
```

- **Explanation**: Patches the Metrics Server deployment to add an argument that allows insecure TLS connections to the Kubelet. This is often needed for local environments or self-signed certificates where secure Kubelet connections might not be available.

  - **Deployment**: `metrics-server`
  - **Namespace**: `kube-system`
  - **Patch Operation**: Adds the `--kubelet-insecure-tls` argument to the `args` list of the container specification, allowing it to bypass TLS certificate verification.

### Step 3: Restart the Metrics Server Deployment

```bash
minikube kubectl -- rollout restart deployment metrics-server -n kube-system
```

- **Explanation**: Restarts the Metrics Server deployment in the `kube-system` namespace. This restart ensures that the patched configuration takes effect.

### Step 4: Apply Application Deployment

```bash
minikube kubectl -- apply -f app-deploy.yml
```

- **Explanation**: Deploys an application to the Kubernetes cluster using a configuration file (`app-deploy.yml`). This YAML file should define the application’s deployment specifications, such as replicas, image, ports, etc.

### Step 5: Display All Resources

```bash
minikube kubectl -- get all
```

- **Explanation**: Lists all Kubernetes resources (pods, services, deployments, etc.) in the current namespace, providing an overview of the cluster's current state and ensuring that the Metrics Server and application deployment are running correctly.

---

This script automates the provisioning of the Metrics Server and application, applying essential configurations for both and verifying that all resources are up and running.