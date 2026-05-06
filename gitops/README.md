# GitOps Layout

Argo CD should manage this directory after the EKS cluster is bootstrapped.

- `argocd/` contains bootstrap-level Argo CD application definitions.
- `envs/` contains the environment entrypoints used by Argo CD root applications.
- `platform/` contains platform add-ons such as autoscaling and observability.
- `applications/` contains frontend and backend Kubernetes manifests.

## Bootstrap Notes

Before applying `argocd/root-app-dev.yaml` or `argocd/root-app-prod.yaml`, push this repository to GitHub so Argo CD can read the desired state.

The AWS Load Balancer Controller manifest is kept in `platform/shared`, but it is not included in the default dev/prod kustomizations yet. It needs an IAM role for service account before being enabled.

The dev application manifests now use images from ECR. Because ECR tag mutability is set to immutable, future CI builds should publish new tags or digests rather than overwriting `dev-v1`.
