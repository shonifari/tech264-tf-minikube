# Minikube with LoadBalancer

- [Minikube with LoadBalancer](#minikube-with-loadbalancer)
  - [App deployment](#app-deployment)
  - [Setting Up Minikube Tunnel with a LoadBalancer](#setting-up-minikube-tunnel-with-a-loadbalancer)
    - [Step 1: Define the Kubernetes Service as a LoadBalancer](#step-1-define-the-kubernetes-service-as-a-loadbalancer)
    - [Step 2: Start Minikube Tunnel](#step-2-start-minikube-tunnel)
    - [Step 3: Check the LoadBalancer IP](#step-3-check-the-loadbalancer-ip)
    - [Step 4: Configure Nginx as a Reverse Proxy](#step-4-configure-nginx-as-a-reverse-proxy)
    - [Step 5: Test and Reload Nginx Configuration](#step-5-test-and-reload-nginx-configuration)
    - [Step 6: Access Your Application](#step-6-access-your-application)

## App deployment

```yaml
---
# SPARTA APP DEPLOYMENT
apiVersion: apps/v1  # specify api to use for deployment
kind : Deployment  # kind of service/object you want to create
metadata:
  name: app-deployment-2
spec:
  selector:
    matchLabels:
      app: sparta-app-2 # look for this labe/tag to match the k8n service

  # Creaate a ReplicaSet with instances/pods
  replicas: 5
  template:
    metadata:
      labels:
        app: sparta-app-2
    spec:
      containers:
      - name: sparta-app-2
        image:  shonifari8/sparta-app:v1
        ports:
        - containerPort: 3000
```

## Setting Up Minikube Tunnel with a LoadBalancer

This guide will help you expose a Kubernetes service on Minikube using a LoadBalancer, with traffic routed through Nginx.

### Step 1: Define the Kubernetes Service as a LoadBalancer

Create a service configuration file, `app-deployment.yml`, with the following content:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: sparta-app-svc-2
  namespace: default
spec:
  ports:
    - protocol: TCP
      port: 30002           # This is the port your clients will use.
      targetPort: 3000       # This is the port your application is running on.
  selector:
    app: sparta-app-2        # Label to match service to deployment
  type: LoadBalancer
```

In this configuration:

- **port** (`30002`) is the external port exposed by the service.
- **targetPort** (`3000`) is the port on which your app is running inside the pod.
- **type: LoadBalancer** will make the service accessible through a LoadBalancer IP.

Apply the configuration using Minikube:

```sh
minikube kubectl -- apply -f app-deployment.yml
```

### Step 2: Start Minikube Tunnel

Run `minikube tunnel` on your machine to set up the LoadBalancer IP:

```sh
minikube tunnel
```

> **Note:** Running `minikube tunnel` may require root privileges and will keep the LoadBalancer IP accessible while it's active.

### Step 3: Check the LoadBalancer IP

After starting `minikube tunnel`, get the external IP assigned to your service:

```sh
minikube kubectl -- get services sparta-app-svc-2

# EXTERNAL-IP: 192.168.49.3
```

The `EXTERNAL-IP` column will display the IP assigned by Minikube.

### Step 4: Configure Nginx as a Reverse Proxy

Edit your Nginx configuration to forward requests on port `9000` to the LoadBalancer IP and port `30002`:

```nginx
server {
    listen 9000;
    listen [::]:9000;
    server_name _;

    access_log /var/log/nginx/access_9000.log;
    error_log /var/log/nginx/error_9000.log;

    location / {
        proxy_pass http://192.168.49.3:30002;  # Replace with your LoadBalancer IP and port.
    }
}
```

### Step 5: Test and Reload Nginx Configuration

1. Test the Nginx configuration for syntax errors:

    ```sh
    sudo nginx -t
    ```

2. If the test passes, reload Nginx to apply the changes:

    ```sh
    sudo systemctl reload nginx
    ```

3. Check the Nginx status to ensure it’s running:

    ```sh
    sudo systemctl status nginx
    ```

### Step 6: Access Your Application

Now, you can access your application through `http://<your-ec2-instance-ip>:9000`, which will route traffic to your Minikube service via the LoadBalancer.

---

This setup allows your EC2 instance to forward traffic to your Minikube cluster using an emulated LoadBalancer. Remember to keep `minikube tunnel` running as it provides the external IP for your LoadBalancer service.