# 0002. Separate Compose stack and manual pipeline for monitoring

- **Status:** Accepted
- **Date:** 2026-08

## Context

I added two self-hosted services to the instance: **Uptime Kuma** (uptime monitoring) and **Umami** (analytics, backed by Postgres). Both have to be reachable through the same nginx that serves the site, under their own subdomains.

The site is deployed on every merge to `main`. The monitoring services change rarely, hold state (Kuma's data, Umami's database), and should keep running while the site is redeployed. If they are down, I lose monitoring exactly when I need it.

## Decision

- Put the monitoring services in their own Compose file, `docker-compose.monitoring.yml`.
- Deploy it with a separate, **manual** workflow (`workflow_dispatch`).
- Connect both stacks through a shared Docker network, `edge`. The site stack creates it, and the monitoring stack joins it as `external`.
- Configure nginx to resolve the monitoring upstreams at request time, so the site does not depend on monitoring being up.

## Alternatives considered

| Option                                                                     | Why not                                                                                                      |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **One Compose file for everything**                                        | Every site deploy would touch the monitoring services, and a mistake in one stack could take the other down. |
| **Monitoring on a second instance**                                        | Better isolation, but doubles the cost and the maintenance for a personal project.                           |
| **Managed services (CloudWatch, Google Analytics, a SaaS uptime checker)** | Valid, but self-hosting was part of the learning goal, and Umami avoids third-party tracking.                |

## Consequences

**Positive**

- Site deploys and monitoring have independent lifecycles and blast radius.
- The site starts and serves normally even if Kuma or Umami are missing.
- Postgres is only reachable on the internal network, never published to the host.

**Negative**

- An ordering dependency: the `edge` network must exist (created by the site stack) before the monitoring stack can start.
- Both stacks share one `.env` file on the server, and the site deploy currently overwrites it (see [Pipelines → Known issues](../pipelines.md#known-issues)).
- Monitoring on the same host it monitors cannot report a full host outage. Kuma will be down too.
