# DNS Setup for CVAT

## Required DNS Records

Create these records in your domain registrar's DNS settings:

### For cvat.feigl.dev (Recommended)

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | cvat | 152.53.16.72 | 3600 |
| AAAA | cvat | fe80::245d:87ff:fe01:ca04 | 3600 |

### For cvat.182bit.dev (Alternative)

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | cvat | 152.53.16.72 | 3600 |
| AAAA | cvat | fe80::245d:87ff:fe01:ca04 | 3600 |

## Verification

After DNS propagation (5-60 minutes), verify:

```bash
# Check A record
dig cvat.feigl.dev +short
# Expected: 152.53.16.72

# Check AAAA record
dig cvat.feigl.dev AAAA +short
# Expected: fe80::245d:87ff:fe01:ca04

# Or use ping
ping cvat.feigl.dev
```

## Update Ansible Configuration

Once DNS is set, update `group_vars/vps.yml`:

```yaml
cvat_host: cvat.feigl.dev  # or cvat.182bit.dev
```

## HTTPS Setup (After CVAT Deployment)

Caddy automatically provisions HTTPS certificates once DNS is configured.

No manual setup required! Access CVAT at:

```
https://cvat.feigl.dev
```

Caddy handles:
- Let's Encrypt certificate provisioning
- Automatic renewal
- HTTP → HTTPS redirect

## Troubleshooting

**DNS not resolving:**
- Wait for propagation (up to 1 hour)
- Check DNS cache: `dig @8.8.8.8 cvat.feigl.dev`
- Verify record at registrar

**HTTPS not working:**
- Ensure port 80 and 443 are open on VPS firewall
- Check Caddy logs: `sudo journalctl -u caddy -f`
- Verify DNS resolves to correct IP
