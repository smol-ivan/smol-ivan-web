# Copilot instructions for smol-ivan-web

## Project overview

This is a static personal portfolio and blog built with Astro 7, TypeScript, Tailwind CSS 4, `astro-icon`, and `astro-mermaid`. Pages are authored as Astro components under `src/pages`; shared document structure, navigation, theme handling, analytics, and the footer live in `src/layouts/Layout.astro`.

The site content is data-driven through Astro content collections:

- `src/content/posts/*.md` is validated by `src/content.config.ts` and rendered by `src/pages/posts.astro` and the dynamic route `src/pages/posts/[id].astro`.
- `src/content/projects/*.md` is validated by the same config and rendered by `src/pages/projects.astro`.
- Post routes are generated at build time with `getStaticPaths`; post metadata and Markdown content are rendered with `getCollection`, `render`, and `<Content />`.

Styling is centralized in `src/styles/global.css`. It imports Tailwind, defines the design tokens and dark-mode variables, and provides project-specific utility/component classes such as `text-headline-lg`, `text-label-caps`, `nav-link-active`, and the post-item hover behavior. Astro components generally compose these tokens with Tailwind classes rather than introducing separate styling systems.

The production image is a multi-stage Docker build: pnpm builds the Astro site, then an Nginx Alpine image serves `dist`. GitHub Actions validates formatting, Astro types/content, and the Docker build on pull requests. Pushes to `main` build and publish the image to ECR and deploy it to EC2 using `docker-compose.yml`; `docker-compose.monitoring.yml` separately deploys Uptime Kuma and Umami on the shared external `edge` network.

## Build, test, and lint commands

Use Node.js 24+ and pnpm. The repository's Nix flake provides Node 24, pnpm, Docker Compose, and lazydocker; `.envrc` loads that flake with direnv.

```bash
pnpm install --frozen-lockfile
pnpm run dev                 # Astro dev server
pnpm exec astro dev --background  # preferred background mode; see AGENTS.md
pnpm run build               # production build to dist/
pnpm run preview             # serve the built dist/ locally
pnpm run check               # Astro/type/content validation
pnpm run format:write        # format the repository with Prettier
pnpm exec prettier --check . # CI formatting check
pnpm exec prettier --check src/pages/posts/[id].astro # check one file
```

There is currently no unit/e2e test framework or test suite in the repository, so there is no single-test command. For a focused change, run `pnpm exec prettier --check <file>` and `pnpm run check`; use `pnpm run build` when the change affects routing, content collections, Markdown rendering, or production output. CI also verifies the container with:

```bash
docker build -t smol-ivan-web:test -f Dockerfile .
```

The CI workflow uses `pnpm install --frozen-lockfile`, Prettier `--check .`, and `pnpm run check`. Keep the lockfile in sync with `package.json`.

## Content and Astro conventions

- Add blog posts under `src/content/posts/` and projects under `src/content/projects/`; do not bypass the collection schemas.
- Post frontmatter requires `title`, `description`, and a YAML date. `tags` defaults to `[]`, `readingTime` defaults to `"5 min read"`, and `image`/`imageAlt` are optional.
- Project frontmatter requires `title`, numeric `year`, numeric `month` from 1–12, `description`, and `href`; `tags` defaults to `[]`.
- Posts are sorted newest-first and grouped by calendar year in `posts.astro`. Projects are sorted by ascending year and descending month in `projects.astro`; preserve this behavior unless intentionally changing the UI.
- Reuse `Layout.astro`, `PostItem.astro`, and `ProjectCard.astro` for shared page structure and list presentation. Keep page metadata in the `<Layout>` props.
- Use `astro-icon` icon names from the installed Iconify JSON packages rather than adding ad hoc icon assets. Mermaid diagrams in Markdown are supported by the `astro-mermaid` integration.
- Keep Astro/TypeScript strictness intact (`tsconfig.json` extends `astro/tsconfigs/strict`). Prefer typed Astro frontmatter props and existing collection types over broad casts.
- Formatting follows `.prettierrc`: four spaces, Prettier with `prettier-plugin-astro`, and the Astro parser for `.astro` files.
- The site uses Astro View Transitions. Header/footer are `transition:persist`; client-side theme initialization must remain compatible with `astro:after-swap` and `astro:page-load`.
- Theme state is stored in `localStorage` under `theme`; the inline head script prevents flash of the wrong theme, while the inline body script updates the toggle after navigation. Preserve both initialization paths when changing theme or navigation behavior.

## Deployment and infrastructure

- `Dockerfile` builds with pnpm and serves the generated static site with Nginx. If changing the runtime server behavior, update `nginx/nginx.conf` and preserve the `/healthz` endpoint used by the Compose healthcheck.
- `docker-compose.yml` expects `ECR_REGISTRY`, `ECR_REPOSITORY`, and `IMAGE_TAG` in the deployment `.env`; it exposes HTTP on port 80 and HTTPS on 443 and mounts Certbot volumes.
- `docker-compose.monitoring.yml` expects `UMAMI_DB_PASSWORD` and `UMAMI_APP_SECRET`, and requires the `edge` network created by the main Compose stack.
- Terraform under `infra/` provisions the AWS resources used by deployment. Do not commit Terraform state, variable files, or secrets; those paths are ignored by `.gitignore`.
- The deploy workflow is intentionally tied to pushes on `main`; the monitoring workflow is manual (`workflow_dispatch`).
