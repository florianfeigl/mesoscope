# Users Ansible Role

Manages user accounts and SSH key distribution on VPS.

## Purpose

Creates the `cvat` service user and distributes SSH public keys.

## Usage

```bash
cd ansible

# Deploy users to VPS
ansible-playbook users.yml -i inventory/hosts.yml
```

## Configuration

Edit `vars/main.yml` to modify the cvat user:

```yaml
users:
  - name: cvat
    groups: docker
    ssh_key: "ssh-ed25519 AAAA..."
```

## Users Created

| User | Groups | Purpose |
|------|--------|---------|
| `cvat` | docker | CVAT service user |

## SSH Key

The cvat user receives the configured public key for automated access.

## Testing

```bash
# Test connection as cvat
ssh cvat@152.53.16.72
```

## Notes

- Other users (florian, cryptobot, etc.) should manage their own SSH keys
- This role is minimal and focused on the CVAT service account only
