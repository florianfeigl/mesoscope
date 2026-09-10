# Mesoscope Ansible Infrastructure

Automated deployment for the mesoscope microscopy project (formerly "CELLAIR").

## Components

| Component | Purpose | Playbook |
|-----------|---------|----------|
| **CVAT** | Image annotation server | `cvat.yml` |
| **Users** | Service user management | `users.yml` |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  VPS (152.53.16.72)                                │
│  ┌─────────────────────────────────────────────┐   │
│  │  Caddy                                      │   │
│  │  ├─ cvat.feigl.dev → localhost:8080        │   │
│  │  ├─ dash.feigl.dev → localhost:8000 (fut.) │   │
│  │  └─ Auto HTTPS (Let's Encrypt)             │   │
│  │                                             │   │
│  │  Modular: /etc/caddy/conf.d/*              │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │  Docker                                     │   │
│  │  └─ CVAT (annotation tool)                 │   │
│  └─────────────────────────────────────────────┘   │
│                                                      │
│  Users: cvat (service account)                      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Raspberry Pi 5 (mesoscope.local)                  │
│  ┌─────────────────────────────────────────────┐   │
│  │  OpenFlexure Server (port 5000)            │   │
│  │  ├─ HQ Camera (IMX477) Thing              │   │
│  │  └─ Web UI for microscope control          │   │
│  └─────────────────────────────────────────────┘   │
│                                                      │
│  Hardware: Hailo-8 NPU, IMX477 HQ Camera            │
└─────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Configure Inventory

Edit `inventory/hosts.yml`:
```yaml
vps:
  hosts:
    cvat-server:
      ansible_host: 152.53.16.72
      ansible_user: florian  # Your admin user
```

### 2. Set Secure Passwords

Edit `group_vars/vps.yml` or use Ansible Vault:
```bash
ansible-vault encrypt group_vars/vps.yml
```

### 3. Deploy

```bash
# Deploy service users
ansible-playbook users.yml -i inventory/hosts.yml

# Deploy CVAT with Caddy reverse proxy
ansible-playbook cvat.yml -i inventory/hosts.yml
```

### 4. Access

- **CVAT:** https://cvat.feigl.dev
- **Default admin:** username `admin`, password from `group_vars/vps.yml`

## DNS Requirements

Create these DNS records:

```
Type   Name    Value              TTL
A      cvat    152.53.16.72       3600
AAAA   cvat    fe80::...          3600
```

Caddy will automatically provision HTTPS certificates.

## Documentation

| Document | Description |
|----------|-------------|
| [VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md) | Complete deployment guide |
| [DNS_SETUP.md](DNS_SETUP.md) | DNS configuration |
| [CADDY.md](CADDY.md) | Caddy configuration (multi-service) |
| [DASHBOARD.md](DASHBOARD.md) | Future dashboard plans |
| [roles/cvat/README.md](roles/cvat/README.md) | CVAT role details |
| [roles/users/README.md](roles/users/README.md) | User management |

## Maintenance

```bash
# Test connection
ansible vps -m ping -i inventory/hosts.yml

# View CVAT logs
ssh cvat@152.53.16.72
cd /opt/cvat/cvat/docker-compose
docker compose logs -f

# Restart CVAT
docker compose restart

# View Caddy logs
sudo journalctl -u caddy -f
```

## Project Structure

```
ansible/
├── site.yml              # Pi 5 deployment (not VPS)
├── cvat.yml              # CVAT deployment playbook
├── users.yml             # User setup playbook
├── inventory/
│   ├── hosts.yml         # Host definitions
│   └── README.md         # Inventory docs
├── group_vars/
│   ├── all.yml           # Global vars (Pi 5)
│   └── vps.yml           # VPS-specific vars
└── roles/
    ├── cvat/
    │   ├── tasks/
    │   ├── templates/    # Caddyfile, cvat.env, docker-compose
    │   ├── handlers/
    │   └── vars/
    └── users/
        ├── tasks/
        └── vars/
```

## Security

- **Passwords:** Use Ansible Vault for production
- **SSH keys:** Managed per-user; only `cvat` service user configured here
- **Firewall:** Ensure ports 22, 80, 443 are open on VPS
- **HTTPS:** Automatic via Caddy + Let's Encrypt
