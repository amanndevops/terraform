#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/user-data.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== User Data Script Started ====="

DOMAIN="test.vishnugaur.in"
EMAIL="amanndevops@gmail.com"
ANSIBLE_DIR="/opt/ansible"

########################################
# Update system & install required tools
########################################
apt-get update -y
apt-get upgrade -y

apt-get install -y \
    ansible \
    git \
    curl \
    certbot \
    python3-certbot-nginx \
    dnsutils \
    gnupg2 \
    ca-certificates \
    lsb-release

########################################
# Clone Ansible Repo
########################################
mkdir -p "$ANSIBLE_DIR"
cd "$ANSIBLE_DIR"

if [ ! -d ansible ]; then
    git clone https://github.com/vsmac/ansible.git
fi

cd ansible

########################################
# Ensure roles/nginx/templates exist
########################################
mkdir -p roles/nginx/templates

########################################
# index.html
########################################
cat <<'EOF' > roles/nginx/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Aman DevOps Server</title>

<style>

:root{
--primary:#00d2ff;
--secondary:#3a7bd5;
--bg:#0f172a;
}

body{
margin:0;
padding:0;
font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;
background:linear-gradient(135deg,#0f172a 0%,#1e293b 100%);
height:100vh;
display:flex;
justify-content:center;
align-items:center;
color:white;
overflow:hidden;
}

.container{
background:rgba(255,255,255,0.05);
backdrop-filter:blur(15px);
border:1px solid rgba(255,255,255,0.1);
padding:3rem;
border-radius:20px;
box-shadow:0 25px 50px -12px rgba(0,0,0,0.5);
text-align:center;
max-width:600px;
width:90%;
animation:fadeIn 1.2s ease-out;
}

@keyframes fadeIn{
from{opacity:0;transform:translateY(20px);}
to{opacity:1;transform:translateY(0);}
}

.icon-box{
font-size:4rem;
margin-bottom:1rem;
filter:drop-shadow(0 0 15px var(--primary));
}

h1{
background:linear-gradient(to right,#00d2ff,#9cedff);
-webkit-background-clip:text;
-webkit-text-fill-color:transparent;
font-size:2.5rem;
margin-bottom:0.5rem;
text-transform:uppercase;
letter-spacing:2px;
}

h2{
color:#94a3b8;
font-weight:400;
font-size:1.2rem;
margin-bottom:2rem;
border-bottom:1px solid rgba(255,255,255,0.1);
padding-bottom:1rem;
}

.status-badge{
display:inline-block;
background:rgba(34,197,94,0.2);
color:#4ade80;
padding:0.5rem 1.5rem;
border-radius:50px;
font-weight:bold;
border:1px solid #22c55e;
margin-top:1rem;
animation:pulse 2s infinite;
}

@keyframes pulse{
0%{box-shadow:0 0 0 0 rgba(34,197,94,0.4);}
70%{box-shadow:0 0 0 15px rgba(34,197,94,0);}
100%{box-shadow:0 0 0 0 rgba(34,197,94,0);}
}

.tech-stack{
margin-top:2rem;
display:flex;
justify-content:center;
gap:15px;
font-size:0.9rem;
color:#cbd5e1;
}

.tech-item{
background:rgba(255,255,255,0.1);
padding:5px 12px;
border-radius:5px;
}

</style>
</head>

<body>

<div class="container">

<div class="icon-box">🚀</div>

<h1>Aman DevOps</h1>
<h2>Infrastructure as Code (IaC)</h2>

<p style="font-size:1.1rem;color:#e2e8f0;">
NGINX + Ansible + Auto SSL
</p>

<div class="status-badge">
✓ Deployment Successful
</div>

<div class="tech-stack">
<span class="tech-item">NGINX</span>
<span class="tech-item">Ansible</span>
<span class="tech-item">Let's Encrypt</span>
<span class="tech-item">Ubuntu</span>
</div>

</div>

</body>
</html>
EOF

########################################
# default.conf
########################################
cat <<EOF > roles/nginx/templates/default.conf
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/html;
    index index.html;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        try_files \$uri \$uri/ /index.html?\$query_string;
    }

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

########################################
# nginx.conf
########################################
cat <<'EOF' > roles/nginx/templates/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;

include /etc/nginx/modules-enabled/*.conf;

events {
worker_connections 768;
}

http {

sendfile on;
tcp_nopush on;

include /etc/nginx/mime.types;
default_type application/octet-stream;

access_log /var/log/nginx/access.log;
error_log /var/log/nginx/error.log;

keepalive_timeout 65;

include /etc/nginx/conf.d/*.conf;
include /etc/nginx/sites-enabled/*;

}
EOF

########################################
# Force localhost execution in playbook
########################################
sed -i 's/hosts:.*/hosts: localhost/' nginx.yml || true

########################################
# Run Ansible Playbook
########################################
echo "Running Ansible Playbook..."

ansible-playbook nginx.yml -i localhost, -c local -b

########################################
# Validate & restart nginx
########################################
nginx -t
systemctl enable nginx
systemctl restart nginx

########################################
# Wait until DNS resolves
########################################
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

until dig +short "$DOMAIN" | grep -q "$PUBLIC_IP"; do
    echo "DNS not ready yet..."
    sleep 10
done

########################################
# Install SSL
########################################
certbot --nginx \
-d "$DOMAIN" \
--agree-tos \
-m "$EMAIL" \
--redirect \
--non-interactive

########################################
# Enable auto renew
########################################
systemctl enable certbot.timer
systemctl start certbot.timer

########################################
# Final check
########################################
systemctl status nginx --no-pager
certbot certificates

echo "===== Deployment Completed Successfully ====="
