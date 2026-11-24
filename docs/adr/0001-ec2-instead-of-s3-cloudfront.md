# 0001. Serve the static site from EC2 instead of S3 + CloudFront

- **Status:** Accepted. Planned to be superseded by a migration to S3 + CloudFront.
- **Date:** 2026-07

## Context

The site is a static Astro build: HTML, CSS, JS and assets, with no server-side logic. The standard way to host that on AWS is an S3 bucket behind CloudFront, with a certificate from ACM. It is cheap, scales without effort and needs no server maintenance.

The goal of this project, however, was not only to publish a website. It was to learn the infrastructure fundamentals that managed services abstract away, as an entry point into DevOps.

## Decision

Run the site on a single EC2 instance, in a Docker container served by nginx, provisioned with Terraform and deployed through GitHub Actions.

## Alternatives considered

| Option                              | Why not (for now)                                                                                                                                                           |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **S3 + CloudFront + ACM**           | The right production answer, but it hides the parts I wanted to learn: Linux hosts, container networking, reverse proxies, certificate management, deployments to a server. |
| **Netlify / Vercel / GitHub Pages** | Zero infrastructure work, so nothing to learn on the infrastructure side.                                                                                                   |
| **ECS / Fargate**                   | Better fit for containers at scale, but adds orchestration concepts before the basics were in place, and costs more than a `t3.micro`.                                      |

## Consequences

**Positive**

- Hands-on experience with every layer: provisioning, bootstrap, Docker, nginx, TLS, CI/CD, IAM.
- The instance had spare capacity to self-host monitoring (Uptime Kuma, Umami), which S3 cannot do.

**Negative**

- A single instance is a single point of failure, with no redundancy across availability zones.
- Operational work that S3 + CloudFront does not need: OS updates, certificate renewal, disk and memory management.
- No CDN: visitors far from `us-west-2` get higher latency.
- A larger attack surface (SSH, an exposed host) for what is static content.

## Follow-up

Migrate the site to S3 + CloudFront with ACM, provisioned with Terraform and deployed with `aws s3 sync` and a cache invalidation. The monitoring stack still needs compute and has to be placed somewhere. See the roadmap in the [main README](../../README.md#known-limitations-and-roadmap).
