# Caddy Main Configuration

This setup uses modular configuration for multiple services.

## Structure

```
/etc/caddy/
├── Caddyfile              # Main config (managed by Caddy package)
└── conf.d/                # Service-specific configs (managed by Ansible)
    ├── cvat              # CVAT reverse proxy
    ├── dashboard         # Future dashboard
    └── ...               # Other services
```

## Adding New Services

### Option 1: Ansible Template (Recommended)

Create `roles/<service>/templates/conf.d/<service>.j2`:

```j2
{{ service_host }} {
    reverse_proxy localhost:{{ service_port }}
    
    log {
        output file /var/log/caddy/{{ service_name }}_access.log
        format json
    }
}
```

Add task to deploy:

```yaml
- name: Deploy Caddy config for {{ service }}
  template:
    src: conf.d/{{ service }}.j2
    dest: /etc/caddy/conf.d/{{ service }}
    mode: "0644"
  notify: reload caddy
```

### Option 2: Manual (Quick Testing)

SSH to VPS and create config:

```bash
ssh cvat@152.53.16.72

sudo nano /etc/caddy/conf.d/dashboard
# Add your config

sudo systemctl reload caddy
```

## Main Caddyfile

The main `/etc/caddy/Caddyfile` (managed by Caddy package) includes:

```caddy
import conf.d/*
```

This automatically loads all configs from `conf.d/`.

## Existing Services

| Service | Domain | Port | Config File |
|---------|--------|------|-------------|
| CVAT | cvat.feigl.dev | 8080 | `conf.d/cvat` |

## Future Services

Planned additions:
- Dashboard: `dash.feigl.dev` → port 8000
- Grafana: `grafana.feigl.dev` → port 3000
- API: `api.feigl.dev` → port 8001

## Caddy Features Used

- **Auto HTTPS**: Automatic Let's Encrypt certificates
- **Reverse Proxy**: Simple `reverse_proxy` directive
- **Security Headers**: HSTS, X-Frame-Options, etc.
- **JSON Logging**: Structured logs for analysis
- **Modular Configs**: `import conf.d/*`

## Troubleshooting

```bash
# Check Caddy config syntax
sudo caddy validate --config /etc/caddy/Caddyfile

# View all loaded configs
sudo caddy adapt --config /etc/caddy/Caddyfile

# Test without reloading
sudo caddy reload --config /etc/caddy/Caddyfile --dry-run

# View logs
sudo journalctl -u caddy -f
cat /var/log/caddy/cvat_access.log
```

## Removing Services

```bash
# Remove config file
sudo rm /etc/caddy/conf.d/<service>

# Reload Caddy
sudo systemctl reload caddy
```

**Note:** Ansible will re-create configs on next deployment. To permanently remove, update Ansible role.
