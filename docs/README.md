# Documentation

Technical documentation for [smol-ivan-web](../README.md). The main README gives the overview; these pages go one level deeper.

| Document                              | Covers                                                                                  |
| ------------------------------------- | --------------------------------------------------------------------------------------- |
| [Pipelines](pipelines.md)             | Every GitHub Actions workflow step by step, secrets, failure modes and manual rollback. |
| [Infrastructure](infrastructure.md)   | Terraform modules, instance bootstrap, and what is intentionally left out of Terraform. |
| [Runtime](runtime.md)                 | Docker image, Compose stacks, nginx, TLS with certbot, networking and resource limits.  |
| [Architecture Decision Records](adr/) | Why things are the way they are, and which alternatives were considered.                |

## Architecture Decision Records

| #                                                | Decision                                                  | Status                       |
| ------------------------------------------------ | --------------------------------------------------------- | ---------------------------- |
| [0001](adr/0001-ec2-instead-of-s3-cloudfront.md) | Serve the static site from EC2 instead of S3 + CloudFront | Accepted (migration planned) |
| [0002](adr/0002-separate-monitoring-stack.md)    | Separate Compose stack and manual pipeline for monitoring | Accepted                     |
| [0003](adr/0003-certbot-sidecar-for-tls.md)      | TLS with a certbot sidecar and shared volumes             | Accepted                     |
| [0004](adr/0004-tag-images-with-commit-sha.md)   | Tag container images with the commit SHA                  | Accepted                     |
