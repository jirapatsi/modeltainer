# Security Baseline

## Gateway Authentication
- The gateway enforces `Authorization: Bearer <token>` for every request. Set the token with the `API_KEY` environment variable.
- Requests missing the header or presenting an invalid token receive `401 Unauthorized`.

## Reverse Proxy Hardening
Put the gateway behind a reverse proxy that terminates TLS, limits request rates and optionally restricts source IPs.

### NGINX
```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    # Allow only trusted networks (optional)
    allow 10.0.0.0/8;
    deny all;

    limit_req zone=gateway burst=10 nodelay;

    location / {
        proxy_pass http://gateway:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
limit_req_zone $binary_remote_addr zone=gateway:10m rate=5r/s;
```

### Traefik
```yaml
http:
  routers:
    gateway:
      rule: Host(`example.com`)
      service: gateway
      entryPoints: ["https"]
      middlewares: ["ratelimit", "ipallow"]
  services:
    gateway:
      loadBalancer:
        servers:
          - url: "http://gateway:8080"
  middlewares:
    ratelimit:
      rateLimit:
        average: 5
        burst: 10
    ipallow:
      ipWhiteList:
        sourceRange:
          - "10.0.0.0/8"
```

## Container Hardening
Run containers with least privileges:

```yaml
services:
  gateway:
    image: your-image
    read_only: true
    user: 1000:1000
    cap_drop: ["ALL"]
    security_opt: ["no-new-privileges:true"]
    mem_limit: 1g
    pids_limit: 100
```

## Basic Security Checks
- Scan images (`docker scan` or `trivy`).
- Run linter/static analysis (`bandit`).
- Perform port scans and fuzz endpoints for unexpected responses.
