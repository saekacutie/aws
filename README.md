# aws — AWS VPS VPN Suite Installer

Installs a multi-protocol VPN server suite on an AWS VPS (EC2):
**SSH · V2Ray · Trojan · Stunnel · WebSocket · SlowDNS**.

## Run (on the VPS, as root)

```bash
chmod +x install.sh
./install.sh
```

## What it does

1. Installs and configures each protocol/service
2. Prints connection details and credentials at the end

## Requirements

- A fresh Ubuntu/Debian VPS (EC2)
- Root access
- AWS security group must allow the ports the installer prints
  (typically 22, 80, 443, plus service-specific ports)

## Security notes

- Re-running should be idempotent — if you customize, keep it that way.
- Rotate any credentials the installer generates; don't reuse them across servers.
