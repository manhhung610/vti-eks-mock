# Mock EKS GitOps Platform

This repository contains a mock production-style AWS EKS platform using Terraform, GitHub Actions, Argo CD, and a self-managed observability stack based on Prometheus, Grafana, and Loki.

## Target Architecture

- Terraform manages AWS infrastructure.
- One shared Terraform root is reused for `dev` and `prod`.
- Environment differences are defined in `infra/dev.terraform.tfvars` and `infra/prod.terraform.tfvars`.
- Terraform remote state is stored in S3, with separate backend keys per environment.
- AWS service modules are custom project modules, with structure and interfaces inspired by `terraform-aws-modules`.
- GitHub Actions handles CI and infrastructure orchestration.
- Argo CD handles in-cluster CD and GitOps reconciliation.
- EKS runs application workloads and platform add-ons.
- Prometheus, Grafana, and Loki provide metrics, dashboards, and logs.

## Terraform Standards

- VPC, EKS, ECR, RDS, and DNS/ACM are implemented as custom internal modules.
- Public, private application, and private database subnets are separated per environment.
- Module interfaces follow reusable input/output patterns inspired by `terraform-aws-modules`.
- Resource names use `hungnm-de000155-<env>-<service>` where possible.
- All common tags include `Owner = "hungnm-de000155"`.
- Dev VPC uses `10.155.0.0/16`.
- Prod VPC uses `10.156.0.0/16`.

## Repository Layout

```text
infra/
  bootstrap/             # Creates shared backend resources such as S3 state bucket
  modules/               # Reusable Terraform modules
  main.tf                # Shared Terraform root for dev and prod
  dev.terraform.tfvars   # Dev values
  prod.terraform.tfvars  # Prod values
gitops/
  envs/                  # Environment entrypoints used by Argo CD root apps
  argocd/                # Argo CD bootstrap manifests
  platform/              # Platform add-ons managed by Argo CD
  applications/          # Application manifests or Helm values
apps/
  frontend/
  backend/
.github/
  workflows/
```

## Current Implementation Status

- `infra/bootstrap` creates the shared S3 state bucket.
- `infra` contains one shared Terraform root for both `dev` and `prod`.
- `gitops/envs/dev` and `gitops/envs/prod` are the Argo CD entrypoints for each environment.
- Platform GitOps currently includes Metrics Server, kube-prometheus-stack, Grafana, Loki, and Promtail.
- Application GitOps currently includes namespace, frontend/backend deployments, ClusterIP services, HPA, and an ALB-style Ingress.
- The dev frontend/backend images are built from `apps/frontend` and `apps/backend`, pushed to ECR, and deployed with the `dev-v1` tag.
- AWS Load Balancer Controller is prepared in `gitops/platform/shared`, but it is not enabled by default because it still needs a real IAM role for service account.
- DNS/ACM are disabled in both environments to keep the mock project cost and permission requirements low.

## Sensitive Values

The project does not store AWS access keys, secret keys, or database passwords in the repository.

`rds_password` is a sensitive Terraform input and must be provided at runtime:

```powershell
$env:TF_VAR_rds_password = "replace-with-your-local-password"
terraform plan -var-file=dev.terraform.tfvars
```

In GitHub Actions, keep using OIDC with `role-to-assume` for AWS access. If RDS is applied from CI, provide the database password through a protected CI variable or an approved secret mechanism, not through `*.tfvars`.

## Dev Application

The mock application is intentionally small but exercises the full platform flow:

- The frontend is a static Nginx site.
- The backend is a dependency-free Node.js HTTP API.
- The frontend calls backend endpoints through relative `/api/*` URLs.
- The Kubernetes Ingress routes `/api` to the backend service and `/` to the frontend service.

Current dev images:

```text
296725355870.dkr.ecr.ap-southeast-1.amazonaws.com/hungnm-de000155-dev-frontend:dev-v1
296725355870.dkr.ecr.ap-southeast-1.amazonaws.com/hungnm-de000155-dev-backend:dev-v1
```

Because ECR repositories are immutable, use a new image tag for each future build, such as a Git commit SHA.

## Dev App CI

`.github/workflows/app-dev.yml` builds the frontend and backend images when files under `apps/**` change on `main`.

The workflow uses GitHub OIDC to assume:

```text
arn:aws:iam::296725355870:role/hungnm-de000155-dev-github-actions-app-ci
```

It then pushes immutable images to ECR with a short commit SHA tag and updates the dev GitOps manifests. Argo CD detects that commit and rolls out the new images to EKS.
