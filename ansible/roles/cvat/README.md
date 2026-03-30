# CVAT Ansible Role

Deploys CVAT (Computer Vision Annotation Tool) on a VPS using Docker Compose.

## Requirements

- Ubuntu 20.04+ or Debian 11+
- 4GB+ RAM (8GB recommended)
- 2+ CPU cores
- 50GB+ disk space

## Usage

### 1. Add to inventory

Edit `ansible/inventory/hosts.yml`:

```yaml
all:
  children:
    vps:
      hosts:
        cvat-server:
          ansible_host: your.vps.ip.address
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

### 2. Configure variables

Edit `ansible/group_vars/vps.yml` (create if needed):

```yaml
# CVAT Configuration
cvat_host: cvat.yourdomain.com
cvat_port: 8080
cvat_admin_password: "YourSecurePassword123!"
cvat_db_password: "SecureDbPass456!"
cvat_redis_password: "SecureRedisPass789!"
cvat_admin_email: admin@yourdomain.com
```

### 3. Run the playbook

```bash
cd ansible
ansible-playbook cvat.yml
```

## Access

After deployment, access CVAT at:

```
http://your.vps.ip.address:8080
```

Default credentials:
- **Username:** admin
- **Password:** (as configured in `cvat_admin_password`)

**IMPORTANT:** Change the admin password after first login!

## HTTPS/SSL Setup

Caddy automatically handles HTTPS! Just ensure DNS is configured:

```
cvat.yourdomain.com  A  152.53.16.72
```

Caddy will:
1. Auto-provision Let's Encrypt certificate
2. Auto-renew before expiry
3. Redirect HTTP → HTTPS

No manual configuration needed.

## Backup

CVAT data is stored in Docker volumes. To backup:

```bash
cd /opt/cvat/cvat/docker-compose

# Backup database
docker compose exec cvat_db pg_dump -U root cvat > cvat_db_backup.sql

# Backup data volumes
docker run --rm \
  -v cvat_cvat_data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/cvat_data_backup.tar.gz /data
```

## Maintenance

```bash
# View CVAT logs
cd /opt/cvat/cvat/docker-compose
docker compose logs -f

# Restart CVAT
docker compose restart

# Update CVAT
cd /opt/cvat/cvat
git pull
docker compose up -d --build

# View Caddy logs
sudo journalctl -u caddy -f
```

## Resources

- [CVAT Documentation](https://docs.cvat.ai/)
- [CVAT GitHub](https://github.com/opencv/cvat)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [DNS Setup](../../DNS_SETUP.md)
- [VPS Deployment Guide](../../VPS_DEPLOYMENT.md)
- [Users Role](../users/README.md)
- [Dashboard Plans](../../DASHBOARD.md)
