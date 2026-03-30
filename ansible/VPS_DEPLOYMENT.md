# VPS Deployment Guide

Complete guide for deploying CVAT annotation server to your VPS.

## Prerequisites

- VPS with Ubuntu 22.04+ or Debian 11+
- DNS records configured (see DNS_SETUP.md)
- SSH access configured
- Ansible installed locally

## Quick Start

### Step 1: DNS Setup

Create DNS record for `cvat.feigl.dev`:
```
A     cvat    152.53.16.72
AAAA  cvat    fe80::245d:87ff:fe01:ca04
```

Wait for propagation (~5-30 minutes).

### Step 2: Verify DNS

```bash
ping cvat.feigl.dev
# Should resolve to 152.53.16.72
```

### Step 3: Deploy Users

```bash
cd /home/feivel/repos/mesoscope/ansible

# Create users and distribute SSH keys
ansible-playbook users.yml -i inventory/hosts.yml
```

This creates:
- `florian` (sudo, docker)
- `cvat` (docker)
- `cryptobot` (docker)

### Step 4: Deploy CVAT

```bash
# Test connection
ansible vps -m ping -i inventory/hosts.yml

# Deploy CVAT
ansible-playbook cvat.yml -i inventory/hosts.yml
```

Deployment takes 5-10 minutes.

### Step 5: Access CVAT

Open browser: **https://cvat.feigl.dev** (after HTTPS setup)

Or temporarily: **http://152.53.16.72:8080**

Default credentials:
- Username: `admin`
- Password: (see `group_vars/vps.yml`)

**Change password after first login!**

## HTTPS Setup

Caddy automatically provisions and renews HTTPS certificates. No manual setup required!

Once DNS is configured and CVAT is deployed, access via:

```
https://cvat.feigl.dev
```

Caddy will:
1. Detect the domain
2. Request Let's Encrypt certificate
3. Auto-renew before expiry

## Firewall Configuration

If UFW is enabled on VPS:

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (for Caddy ACME challenge)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

## Verification Checklist

- [ ] DNS resolves: `ping cvat.feigl.dev`
- [ ] SSH works: `ssh cvat@152.53.16.72`
- [ ] CVAT accessible: `http://152.53.16.72:8080`
- [ ] HTTPS working: `https://cvat.feigl.dev` (Caddy auto-provisions)
- [ ] Caddy logs clean: `sudo journalctl -u caddy`

## Maintenance

```bash
# View CVAT logs
ssh cvat@152.53.16.72
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

# View Caddy logs
sudo journalctl -u caddy -f
# Or access logs: /var/log/caddy/cvat_access.log
```

## Troubleshooting

**Cannot connect via SSH:**
```bash
# Check if VPS is reachable
ping 152.53.16.72

# Test SSH with verbose output
ssh -v florian@152.53.16.72
```

**CVAT not starting:**
```bash
ssh florian@152.53.16.72
cd /opt/cvat/cvat/docker-compose
docker compose ps
docker compose logs cvat
```

**Out of disk space:**
```bash
df -h
docker system prune -a
```

## Next Steps After Deployment

1. **Create CVAT user account** for annotation work
2. **Configure project** with cell classes (osteoblast, epithelial, calcium)
3. **Upload test images** from data collection
4. **Start annotation** (see model/docs/SETUP.md)

## Resources

- [CVAT Documentation](https://docs.cvat.ai/)
- [DNS Setup](DNS_SETUP.md)
- [Users Role](roles/users/README.md)
- [CVAT Role](roles/cvat/README.md)
