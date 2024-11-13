#!/bin/bash
# 1. Provision Docker
# 2. Provision minikube
# 3. minikube addons
# 4. Provision nginx to expose the required NodePort when going to the public IP of the instance




echo "[PROVISIONING MINIKUBE]: Installing minikube..."
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

echo "[PROVISIONING MINIKUBE]: Setting driver to Docker"
minikube config set driver docker

echo "[PROVISIONING MINIKUBE]: Minikube is configured to use Docker as the driver."


echo "[UPDATE & UPGRADE PACKAGES]" 
# Update packages
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# DOCKER
# Add Docker's official GPG key:
echo "[PROVISIONING DOCKER]: Adding Dockers GPG key"
# Install docker
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "[PROVISIONING DOCKER]: Adding repository to Apt sources"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

echo "[PROVISIONING DOCKER]: Installing Docker"
sudo DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
echo "[PROVISIONING DOCKER]: Complete\n"

# Check if the user is already part of the docker group
if ! groups ubuntu | grep -q '\bdocker\b'; then
    echo "[PROVISIONING MINIKUBE]: Adding ubuntu to the docker group..."
    sudo usermod -aG docker ubuntu

    echo "[PROVISIONING MINIKUBE]: Restarting script to apply Docker group permissions..."
    exec sg docker "$0"
    exit
fi
# MINIKUBE

# Install minikube
echo "[PROVISIONING MINIKUBE]: Downloading minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

echo "[PROVISIONING MINIKUBE]: Installing minikube..."
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64


#echo "[PROVISIONING MINIKUBE]: Creating user group named 'docker'"

echo "Running as $(whoami)"
# Run Minikube as 'ubuntu' user after Docker group is applied
sudo -u ubuntu -i bash <<'EOF'

echo "[PROVISIONING MINIKUBE]: Starting Minikube as 'ubuntu' user..."
echo "Running as $(whoami)"

# Running Minikube as the 'ubuntu' user to ensure it uses Docker
minikube start

minikube status
echo "[PROVISIONING MINIKUBE]: Exporting Minikube IP"
MINIKUBE_IP=$(minikube ip)
echo "[PROVISIONING MINIKUBE]: Exported Minikube IP: $MINIKUBE_IP"
echo "[PROVISIONING MINIKUBE]: Complete"
echo

# NGINX
echo "[PROVISIONING NGINX]: Installing..."
# Install Nginx
echo "Installing Nginx..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install nginx -y
echo "Done!"

echo "[PROVISIONING NGINX]: Setting reverse proxy to $MINIKUBE_IP:30001"
# Use sed to update the proxy settings in the configuration file
sudo sed -i "s|try_files \$uri \$uri/ =404;|proxy_pass http://$MINIKUBE_IP:30001;|" /etc/nginx/sites-available/default

# Check syntax error
sudo nginx -t

# Restart Nginx
echo "[PROVISIONING NGINX]: Restarting..."
sudo systemctl restart nginx
echo "[PROVISIONING NGINX]: Complete"

EOF






