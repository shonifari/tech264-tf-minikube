# Deploying containerised application with Minikube

- [Deploying containerised application with Minikube](#deploying-containerised-application-with-minikube)
  - [Infrastructure](#infrastructure)
  - [App 1: basic deployment](#app-1-basic-deployment)
  - [App 2: Tunnel \& LoadBalancer deployment](#app-2-tunnel--loadbalancer-deployment)

## Infrastructure

First we need to set up the [infrastructure using terraform](infrastructure/README.md)

## App 1: basic deployment

For a basic deployment guide check [here](k8s-yaml-definitions/app-deployment/README.md)

## App 2: Tunnel & LoadBalancer deployment

For a deployment using minikube tunnel and load balancer  check [here](k8s-yaml-definitions/app-tunnel-lb-deployment/README.md)