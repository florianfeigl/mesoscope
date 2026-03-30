# CVAT Deployment Quick Start

## Prerequisites

- **VPS:** Ubuntu 22.04+ or Debian 11+, 4GB+ RAM, 50GB+ disk
- **SSH access** to VPS (root or sudo user)
- **Ansible** installed locally (>= 2.10)

## Step 1: Configure VPS Access

Edit `inventory/hosts.yml`:

```yaml
vps:
  hosts:
    cvat-server:
      ansible_host: your.vps.ip.address  # Your VPS IP
      ansible_user: root
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

## Step 2: Set Secure Passwords

**Option A: Edit `group_vars/vps.yml` directly** (for testing)

```yaml
cvat_admin_password: "YourSecurePassword123!"
cvat_db_password: "SecureDbPass456!"
cvat_redis_password: "SecureRedisPass789!"
```

**Option B: Use Ansible Vault** (recommended for production)

```bash
# Encrypt the vars file
ansible-vault encrypt group_vars/vps.yml

# Run playbook with vault password
ansible-playbook cvat.yml --ask-vault-pass
```

## Step 3: Test Connection

```bash
cd ansible

# Test SSH connection
ansible vps -m ping -i inventory/hosts.yml

# Expected output:
# cvat-server | SUCCESS => {"changed": false, "ping": "pong"}
```

## Step 4: Deploy CVAT

```bash
ansible-playbook cvat.yml -i inventory/hosts.yml
```

Deployment takes ~5-10 minutes (Docker pull, CVAT build, database init).

## Step 5: Access CVAT

```
URL: http://your.vps.ip.address:8080
Username: admin
Password: (as configured in cvat_admin_password)
```

**IMPORTANT:** Change admin password after first login via CVAT UI!

## Optional: HTTPS Setup

For production use with HTTPS:

```bash
# SSH into VPS
ssh root@your.vps.ip.address

# Install nginx and certbot
apt install nginx certbot python3-certbot-nginx -y

# Get SSL certificate (update domain)
certbot --nginx -d cvat.yourdomain.com

# Configure nginx reverse proxy
cat > /etc/nginx/sites-available/cvat << 'EOF'
server {
    listen 80;
    server_name cvat.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name cvat.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/cvat.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cvat.yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable and reload
ln -s /etc/nginx/sites-available/cvat /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

## Maintenance

```bash
# View logs
cd /opt/cvat/cvat/docker-compose
docker compose logs -f

# Restart CVAT
docker compose restart

# Backup database
docker compose exec cvat_db pg_dump -U root cvat > backup.sql

# Update CVAT
cd /opt/cvat/cvat
git pull
docker compose up -d --build
```

## Troubleshooting

**CVAT not starting:**
```bash
docker compose ps          # Check container status
docker compose logs cvat   # View application logs
```

**Out of disk space:**
```bash
df -h                      # Check disk usage
docker system prune -a     # Clean unused containers/images
```

**Port 8080 already in use:**
Edit `group_vars/vps.yml`:
```yaml
cvat_port: 8081  # Use different port
```
Then re-run: `ansible-playbook cvat.yml`

## Resources

- [CVAT Documentation](https://docs.cvat.ai/)
- [CVAT GitHub](https://github.com/opencv/cvat)
- [Ansible Inventory Guide](inventory/README.md)
