# 0004. Tag container images with the commit SHA

- **Status:** Accepted
- **Date:** 2026-07

## Context

Every merge to `main` builds a new image and deploys it. I need to know which version of the code is running in production, and be able to go back to a previous one if a deploy breaks something.

The simplest approach, pushing and pulling only `latest`, answers neither question: `latest` points to whatever was pushed last, and the previous image loses its only tag.

## Decision

- Tag every image with the **full commit SHA** (`github.sha`), and also with `latest`.
- Deploy by SHA: the pipeline writes `IMAGE_TAG=<sha>` to the server's `.env`, and `docker-compose.yml` uses `${IMAGE_TAG}`.
- Keep old images in ECR. Only the server's local cache is pruned.

## Alternatives considered

| Option                           | Why not                                                                                                                    |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **`latest` only**                | No traceability and no way to roll back to a known image.                                                                  |
| **Semantic versions (`v1.2.3`)** | Meaningful for released software. For a site deployed continuously from `main`, it adds a manual step for no real benefit. |
| **Image digests**                | The most precise (immutable), but harder to read and to map back to a commit.                                              |

## Consequences

**Positive**

- Production always maps to one exact commit, visible in `.env` and in `docker ps`.
- Rollback is changing one variable and running `docker compose up -d` (see [Pipelines → Rolling back](../pipelines.md#rolling-back)).

**Negative**

- The ECR repository must stay `MUTABLE` because `latest` is overwritten. Nothing technically prevents a SHA tag from being overwritten too.
- With no ECR lifecycle policy, images accumulate indefinitely. A policy keeping the last N images would cap storage costs.
