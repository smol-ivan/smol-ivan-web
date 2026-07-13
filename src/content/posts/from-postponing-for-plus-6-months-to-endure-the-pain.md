---
title: "From delaying almost half a year to get to build my own page enduring the pain"
description: "A deep dive into automating modern web infrastructure using Terraform, Docker, GitHub Actions, and self-hosted VPS environments with enforced branch security."
date: 2026-07-13
tags: ["DEVOPS", "INFRASTRUCTURE", "ASTRO"]
image: "https://lh3.googleusercontent.com/aida-public/AB6AXuCyAxRLCukPrSXqtACFyFzLO86fpDsUxiwYFXdKC43Z1K9O4oBsbt_oawLYjQVwrdl_m3a1LjuDEtdCC-glBSnJBI4mqZCrhIQ6TIW8X0sJWoLVAZuQKWQ6iAQVeCDpG25GBgPn-6c3EZLqC112I4YnzA5NY_MNUpVQ81kDttJXcpjYUjBs64ArcHIC1PNlcubGpc-_5yPQToBTwNvHH-5radk9gVftMUrMieqjMN4wcxlm76W-okKITw"
imageAlt: "A terminal interface displaying a successful multi-stage Docker build and a completed GitHub Actions pipeline execution."
readingTime: "6 min read"
---

Deploying a web application it doesn't seems to difficult, until you steer in that direction ...

I really don't like to be told what can I expect from the future. And today I remember every time I'd hit my brain.

## 1. Declarative infrastructure

Now that I look back, there is a loot of things(like gettin stuck) that I could avoid if someone just stick to read the f\* documentation.

It is insane how can we declare an entire setup with just a couple lines of code.

```hcl
# infra/main.tf
resource "aws_instance" "web_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu LTS
  instance_type = "t2.micro"

  tags = {
    Name = "smol-ivan-vps"
  }
}

resource "aws_ecr_repository" "app_repo" {
  name                 = "smol-ivan-web"
  image_tag_mutability = "MUTABLE"
}
```

## 2. Complete development flow

```mermaid
graph TD
    %% Estilos Generales Minimalistas
    classDef default fill:#fff,stroke:#333,stroke-width:1px,color:#000;
    classDef guardrail fill:#f5f5f5,stroke:#999,stroke-width:1px,stroke-dasharray: 5 5,color:#333;
    classDef cloud fill:#fafafa,stroke:#222,stroke-width:2px,color:#000;


    %% Flujo 1: CI (Pull Request Guardrails)
    subgraph CI ["1. Continuous Integration (PR Guardrails)"]
        A[Developer: Pull Request] --> B{GitHub Actions CI}
        B -->|Step 1| C[Validate Astro Syntax & Build]
        C -->|Step 2| D[Verify Docker Multi-Stage Build]
        D --> E{All Checks Passed?}
        E -->|No| F[Merge Blocked]
        E -->|Yes| G[Merge Allowed to Main]
        F -->|Fix/Review| A
    end
    style CI fill:none,stroke:#ccc,stroke-width:1px

    %% Flujo 2: CD (Build, ECR & Delivery)
    subgraph CD ["2. Continuous Deployment (Automation)"]
        G --> H[Trigger CD Pipeline on Main]
        H --> I[Execute Multi-Stage Docker Build]
        I --> J[Tag Container Image]
        J --> K[Push Image to Amazon ECR]
    end
    style CD fill:none,stroke:#ccc,stroke-width:1px

    %% Flujo 3: VPS Update
    subgraph VPS ["3. Target Infrastructure (VPS)"]
        K --> L[Establish Secure SSH Connection]
        L --> M[Pull Latest Image from ECR]
        M --> N[Stop Old Container]
        N --> O[Run New Container & Reload Nginx]
    end
    style VPS fill:none,stroke:#ccc,stroke-width:1px

    %% Asignación de estilos
    class B,E guardrail;
    class K,M cloud;
```
