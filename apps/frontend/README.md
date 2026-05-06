# Frontend

Small static web UI for the mock EKS GitOps platform.

The app calls backend endpoints through relative `/api/*` URLs. In EKS, the ALB Ingress routes `/api` to the backend service and `/` to the frontend service.

