# 0003. TLS with a certbot sidecar and shared volumes

- **Status:** Accepted
- **Date:** 2026-07

## Context

The site and the monitoring subdomains must be served over HTTPS. The instance is directly exposed to the internet (no load balancer or CDN in front of it), so TLS has to be terminated on the instance, and certificates have to be obtained and renewed there.

## Decision

Use Let's Encrypt with **certbot running as a sidecar container** in the same Compose stack as nginx:

- An `acme-challenge` volume, shared by both, for HTTP-01 challenges.
- A `certbot-etc` volume where certbot writes certificates and nginx mounts them **read-only**.
- Certbot runs `certbot renew` in a loop every 12 hours.
- A weekly host cron job restarts the site container so nginx loads renewed certificates.

## Alternatives considered

| Option                            | Why not                                                                                                                                                                            |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Certbot installed on the host** | Works, but puts state and configuration outside of Docker and outside of version control.                                                                                          |
| **Caddy instead of nginx**        | Automatic HTTPS out of the box, the simplest option. I chose nginx because it is more widespread and I wanted to understand the certificate lifecycle instead of having it hidden. |
| **Traefik**                       | Automatic certificates and service discovery, but more than a single site needs.                                                                                                   |
| **ACM**                           | Free and managed, but ACM certificates cannot be installed on an EC2 instance. They require a load balancer or CloudFront in front of it.                                          |

## Consequences

**Positive**

- The whole TLS setup is declared in `docker-compose.yml` and versioned with the code.
- nginx cannot modify certificates (read-only mount).
- Renewal is automatic.

**Negative**

- The first certificate must be requested manually. The container only renews.
- nginx does not detect new certificates on its own: there can be a delay of up to a week between renewal and the new certificate being served. That is safe with 90-day certificates renewed at ~60 days, but a `nginx -s reload` triggered by a certbot deploy hook would be more precise.
- The restart cron lives in `user_data`, so it only exists on instances created after it was added.

This decision goes away with the migration to S3 + CloudFront, where ACM handles certificates ([ADR 0001](0001-ec2-instead-of-s3-cloudfront.md)).
