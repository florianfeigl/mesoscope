# Ansible Inventory Configuration

This directory contains the Ansible inventory for CELLAIR infrastructure.

## Host Groups

### `rpi5` - Raspberry Pi 5 (Microscope)
- **Hostname:** `mesoscope.local` (or static IP)
- **User:** `lab`
- **Purpose:** OpenFlexure server, HQ Camera (IMX477), Hailo-8 inference

### `vps` - VPS (CVAT Annotation Server)
- **Hostname:** Your VPS IP or domain
- **User:** `root`
- **Purpose:** CVAT annotation tool for cell image labeling

## SSH Configuration

Ensure SSH keys are set up for both hosts:

```bash
# For Raspberry Pi
ssh-copy-id lab@mesoscope.local

# For VPS
ssh-copy-id root@your.vps.ip.address
```

## Testing Connection

```bash
# Test Pi connection
ansible rpi5 -m ping -i inventory/hosts.yml

# Test VPS connection
ansible vps -m ping -i inventory/hosts.yml
```

## Editing Inventory

Edit `hosts.yml` to update:
- IP addresses/hostnames
- SSH key paths
- CVAT credentials (in `group_vars/vps.yml`)

## Security Notes

1. **Never commit passwords** - Use Ansible Vault for production:
   ```bash
   ansible-vault encrypt group_vars/vps.yml
   ansible-playbook cvat.yml --ask-vault-pass
   ```

2. **Change default passwords** after deployment

3. **Use firewall** on VPS:
   ```bash
   ufw allow 22/tcp
   ufw allow 80/tcp   # Caddy ACME challenge
   ufw allow 443/tcp
   ufw enable
   ```

4. **SSH key management** - Each user manages their own keys; this repo only configures the `cvat` service user
