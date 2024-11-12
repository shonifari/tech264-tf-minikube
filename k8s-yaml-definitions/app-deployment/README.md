# App deployment using Minikube

- [App deployment using Minikube](#app-deployment-using-minikube)
  - [Minikube Deployment with NodePort and Nginx Reverse Proxy](#minikube-deployment-with-nodeport-and-nginx-reverse-proxy)
    - [Step 1: Define the Kubernetes Service with NodePort](#step-1-define-the-kubernetes-service-with-nodeport)
    - [Step 2: Apply the Kubernetes Service Configuration](#step-2-apply-the-kubernetes-service-configuration)
    - [Step 3: Get the Minikube IP Address](#step-3-get-the-minikube-ip-address)
    - [Step 4: Configure Nginx as a Reverse Proxy](#step-4-configure-nginx-as-a-reverse-proxy)
    - [Step 5: Test and Reload Nginx Configuration](#step-5-test-and-reload-nginx-configuration)
    - [Step 6: Access Your Application](#step-6-access-your-application)
    - [Recap of the Setup](#recap-of-the-setup)

## Minikube Deployment with NodePort and Nginx Reverse Proxy

This guide explains how to set up a Minikube deployment with a `NodePort` service and configure Nginx to forward traffic to your service.

### Step 1: Define the Kubernetes Service with NodePort

Create a Kubernetes service configuration file, `app-deployment.yml`, with the following content:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: sparta-app-svc-1
  namespace: default
spec:
  ports:
    - nodePort: 30001  # External port on the host for accessing the service
      port: 3000        # Internal port inside the container
      targetPort: 3000  # Port where the app is running in the pod
  selector:
    app: sparta-app-1  # Label to match service to deployment
  type: NodePort
```

In this configuration:

- **nodePort** (`30001`): This is the port exposed on your Minikube host for accessing the service externally.
- **port** (`3000`): This is the port used internally within your Kubernetes cluster.
- **targetPort** (`3000`): This is the port the application is listening to within the pod.
- **type: NodePort**: This exposes the service on a static port (`30001`) on the host, making it accessible externally.

### Step 2: Apply the Kubernetes Service Configuration

Apply the configuration using Minikube to create the service:

```sh
minikube kubectl -- apply -f app-deployment.yml
```

This command will create the `sparta-app-svc-1` service with a `NodePort` of `30001` to expose your app externally.

### Step 3: Get the Minikube IP Address

To access the service externally, first retrieve the IP address of your Minikube instance:

```sh
minikube ip
```

This will return the IP address where Minikube is running (e.g., `192.168.49.2`). Use this IP to configure Nginx.

### Step 4: Configure Nginx as a Reverse Proxy

Next, configure Nginx to forward incoming traffic on port `80` to the `NodePort` (`30001`) of the Minikube service. Edit your Nginx configuration:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    access_log /var/log/nginx/access_80.log;
    error_log /var/log/nginx/error_80.log;

    location / {
        proxy_pass http://192.168.49.2:30001;  # Replace with your Minikube IP and NodePort
    }
}
```

### Step 5: Test and Reload Nginx Configuration

1. **Test the Nginx configuration** for syntax errors:

    ```sh
    sudo nginx -t
    ```

2. **Reload Nginx** to apply the changes:

    ```sh
    sudo systemctl reload nginx
    ```

3. **Check the status of Nginx** to ensure it is running properly:

    ```sh
    sudo systemctl status nginx
    ```

### Step 6: Access Your Application

Now, you can access your application via `http://<your-ec2-instance-ip>` on port `80`, and Nginx will forward the requests to the Minikube service running on port `30001`.

---

### Recap of the Setup

- **Kubernetes Service**: Defined as `NodePort` to expose the app on port `30001`.
- **Minikube Tunnel**: Not required since you’re using `NodePort`, but Minikube IP is used in the Nginx configuration.
- **Nginx Reverse Proxy**: Configured to forward traffic from port `80` to Minikube’s IP and `NodePort` (`30001`).

This setup enables external access to your Minikube service through the EC2 instance with Nginx acting as the reverse proxy.