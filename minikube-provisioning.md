

# Provisioning Docker, Minikube, and Nginx

- [Provisioning Docker, Minikube, and Nginx](#provisioning-docker-minikube-and-nginx)
  - [Key concepts](#key-concepts)
    - [Why We Need to Restart the Script with Docker Group Permissions](#why-we-need-to-restart-the-script-with-docker-group-permissions)
    - [Why We Avoid Running Minikube as Root](#why-we-avoid-running-minikube-as-root)
  - [Overview of Steps](#overview-of-steps)
    - [1. Installing and Configuring Docker](#1-installing-and-configuring-docker)
      - [Adding the `ubuntu` User to the Docker Group](#adding-the-ubuntu-user-to-the-docker-group)
    - [2. Installing and Configuring Minikube](#2-installing-and-configuring-minikube)
    - [3. Starting Minikube as the `ubuntu` User](#3-starting-minikube-as-the-ubuntu-user)
    - [4. Installing and Configuring Nginx](#4-installing-and-configuring-nginx)
    - [Final Output and Status](#final-output-and-status)

This script provisions Docker, Minikube, and Nginx on a server. It automates the installation and configuration of each component, ensuring Minikube uses Docker as its driver and setting up Nginx as a reverse proxy to expose a service running on Minikube.

## Key concepts

### Why We Need to Restart the Script with Docker Group Permissions

When we add the `ubuntu` user to the `docker` group, this change does not take effect immediately for the current session. Normally, group changes only take effect after the user logs out and logs back in. However, since the script is running in a non-interactive environment, we cannot rely on a logout/login to apply the new group permissions. Instead, we use the `exec sg docker "$0"` command to restart the script with the `docker` group permissions applied.

- **Effect of `sg docker "$0"`**: This command re-runs the entire script within a new shell session where the `ubuntu` user is a member of the `docker` group.
- **Why This Is Necessary**: Minikube requires the user to have non-root Docker access to start containers. By re-running the script, we ensure that the `ubuntu` user has immediate access to Docker without needing to log out and back in, thus allowing Minikube to start successfully.

### Why We Avoid Running Minikube as Root

Running Minikube as a non-root user, like `ubuntu`, is best practice for security and environment consistency. Here’s why:

1. **Security Concerns**: Running Minikube as `root` would mean that all Kubernetes containers and components, along with any processes they spawn, would have root-level access. This can create significant security risks, as any vulnerability in those containers could lead to privilege escalation.

2. **Docker Permission Management**: The Docker daemon itself runs as `root`, but by granting `docker` group access to the `ubuntu` user, we enable Minikube to start and manage containers through Docker without requiring root permissions.

3. **Environment Consistency**: Using a dedicated, non-root user to manage Minikube is consistent with Kubernetes’ general principle of running applications with the minimum privileges necessary. This separation of privileges helps prevent unintentional system changes and limits the impact of potential misconfigurations.

By re-running the script with `docker` group permissions applied to the `ubuntu` user, we set up Minikube to operate with restricted privileges, following best practices for security and maintainability.

---

## Overview of Steps

1. **Provision Docker**: Installs Docker and configures permissions for the `ubuntu` user.
2. **Provision Minikube**: Installs Minikube and sets it to use Docker as its driver.
3. **Start Minikube**: Starts Minikube as the `ubuntu` user.
4. **Provision Nginx**: Installs and configures Nginx to act as a reverse proxy to Minikube’s exposed service.

---

### 1. Installing and Configuring Docker

The first part of the script updates system packages, installs Docker, and adds the `ubuntu` user to the Docker group.

```bash
# Update and upgrade system packages
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install dependencies and add Docker's GPG key
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker packages
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### Adding the `ubuntu` User to the Docker Group

After Docker is installed, the `ubuntu` user is added to the Docker group to allow non-root access to Docker. The script then re-executes itself using `exec sg docker "$0"` to apply the group change without requiring a logout/login.

```bash
# Check if the 'ubuntu' user is in the docker group; add if not
if ! groups ubuntu | grep -q '\bdocker\b'; then
    sudo usermod -aG docker ubuntu
    echo "Restarting script to apply Docker group permissions..."
    exec sg docker "$0"
    exit
fi
```

---

### 2. Installing and Configuring Minikube

The script downloads and installs Minikube, setting it to use Docker as the driver.

```bash
# Download Minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube binary
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Set Docker as the Minikube driver
minikube config set driver docker
```

---

### 3. Starting Minikube as the `ubuntu` User

To ensure Minikube runs with the correct permissions, it is started as the `ubuntu` user. This section runs the `minikube start` command and exports Minikube's IP address for later use.

```bash
sudo -u ubuntu -i bash <<'EOF'
echo "Starting Minikube as 'ubuntu' user..."
minikube start
minikube status

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Exported Minikube IP: $MINIKUBE_IP"
EOF
```

Here’s a breakdown of the code:

- **`sudo -u ubuntu -i bash`**: This part of the command switches to the `ubuntu` user and initiates an interactive shell (`-i`) as `ubuntu`, which allows us to run commands in that user’s environment.

- **`<<'EOF'`**: This is a "Here Document" syntax, which allows us to run multiple commands within the `sudo` session as `ubuntu`. Everything between `<<'EOF'` and the closing `EOF` is executed in the `ubuntu` user’s environment.

- **`echo "Starting Minikube as 'ubuntu' user..."`**: Prints a message indicating that Minikube is starting under the `ubuntu` user.

- **`minikube start`**: Starts the Minikube cluster, using Docker as the container driver (which we configured earlier). By running this as `ubuntu`, it uses `ubuntu`’s environment and permissions.

- **`minikube status`**: Checks and prints the current status of Minikube, confirming that it’s running and which components are active.

- **`MINIKUBE_IP=$(minikube ip)`**: Retrieves Minikube’s IP address and assigns it to the `MINIKUBE_IP` variable. This IP is useful for accessing Minikube services externally, such as setting up a reverse proxy.

- **`echo "Exported Minikube IP: $MINIKUBE_IP"`**: Prints the exported Minikube IP to confirm that it’s been successfully retrieved and stored.

- **`EOF`**: This signifies the end of the "Here Document," meaning all commands up to this point will be executed as the `ubuntu` user within the `sudo -u ubuntu` session. 

In summary, this block:
- Switches to the `ubuntu` user.
- Starts Minikube as `ubuntu`, verifies its status, retrieves its IP address, and prints it.V

---

### 4. Installing and Configuring Nginx

The script installs Nginx and sets it up as a reverse proxy. It updates the Nginx configuration to proxy traffic from the server’s IP to the Minikube NodePort.

```bash
# Install Nginx
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# Configure Nginx reverse proxy to Minikube IP and port
sudo sed -i "s|try_files \$uri \$uri/ =404;|proxy_pass http://$MINIKUBE_IP:30001;|" /etc/nginx/sites-available/default

# Check for syntax errors and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

---

### Final Output and Status

The script outputs Minikube and Nginx statuses and configurations at each stage, ensuring each component is set up correctly before moving to the next. This structured approach ensures Docker permissions are applied effectively, Minikube is correctly configured to use Docker, and Nginx routes traffic to Minikube services.
