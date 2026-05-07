# Báo cáo project Mock EKS GitOps Platform

Ngày cập nhật: 07/05/2026

## 1. Mục tiêu project

Project này mô phỏng một nền tảng triển khai ứng dụng trên AWS EKS theo hướng Infrastructure as Code và GitOps.

Mục tiêu chính là chứng minh một luồng triển khai hoàn chỉnh từ source code đến workload chạy trong Kubernetes:

```text
Developer push code
GitHub Actions build Docker image
Amazon ECR lưu image
GitHub Actions cập nhật GitOps manifest
Argo CD đồng bộ manifest
Amazon EKS rollout ứng dụng
AWS Application Load Balancer expose ứng dụng
Prometheus, Grafana, Loki phục vụ monitoring và logging
```

Project tập trung hoàn thiện môi trường dev để phục vụ deadline. Môi trường prod chưa triển khai vì không phải điều kiện bắt buộc của phạm vi hiện tại.

## 2. Phạm vi đã hoàn thành

1. Terraform quản lý hạ tầng AWS cho môi trường dev.

2. GitHub Actions quản lý CI cho ứng dụng frontend và backend.

3. Amazon ECR lưu Docker image frontend và backend.

4. Argo CD quản lý Kubernetes manifests theo mô hình GitOps.

5. EKS chạy application workload và platform add-ons.

6. AWS Load Balancer Controller tạo Application Load Balancer từ Kubernetes Ingress.

7. Prometheus, Grafana, Loki và Promtail cung cấp monitoring và logging trong cluster.

8. Terraform workflow đã có IAM role riêng qua GitHub OIDC để plan và apply hạ tầng.

## 3. Thông tin môi trường dev

AWS account:

```text
296725355870
```

AWS region:

```text
ap-southeast-1
```

EKS cluster:

```text
hungnm-de000155-dev-eks
```

Application Load Balancer:

```text
k8s-mockapp-mockapp-350f2d5889-1668082414.ap-southeast-1.elb.amazonaws.com
```

Namespace ứng dụng:

```text
mock-app
```

Image backend đang khai báo trong GitOps:

```text
296725355870.dkr.ecr.ap-southeast-1.amazonaws.com/hungnm-de000155-dev-backend:3276531b8879
```

Image frontend đang khai báo trong GitOps:

```text
296725355870.dkr.ecr.ap-southeast-1.amazonaws.com/hungnm-de000155-dev-frontend:3276531b8879
```

## 4. Kiến trúc tổng quan

Các thành phần chính:

1. Terraform quản lý tài nguyên AWS.

2. GitHub là nơi lưu source code, Terraform code, GitOps manifest và workflow.

3. GitHub Actions build image, push image lên ECR và cập nhật GitOps manifest.

4. Argo CD đọc desired state từ GitHub và đồng bộ vào EKS.

5. EKS chạy frontend, backend và platform add-ons.

6. AWS Load Balancer Controller chuyển Kubernetes Ingress thành AWS ALB.

7. Prometheus và Grafana phục vụ metrics.

8. Loki và Promtail phục vụ logs.

Phân chia trách nhiệm:

```text
Terraform: AWS infrastructure
Argo CD: Kubernetes runtime state
GitHub Actions: CI và orchestration
GitHub repository: source of truth
```

## 5. Hạ tầng do Terraform quản lý

Terraform root nằm tại:

```text
infra
```

State backend dev:

```text
infra/backend-dev.hcl
```

S3 state bucket:

```text
hungnm-de000155-mock-eks-terraform-state
```

State key:

```text
envs/dev/terraform.tfstate
```

Các nhóm tài nguyên chính đã tạo:

1. VPC và subnet.

2. Internet Gateway và NAT Gateway.

3. Route tables.

4. ECR repositories cho frontend và backend.

5. EKS cluster.

6. EKS managed node group.

7. EKS add-ons gồm VPC CNI, CoreDNS, kube-proxy và EKS Pod Identity Agent.

8. RDS PostgreSQL.

9. IAM roles cho EKS, GitHub Actions và AWS Load Balancer Controller.

10. OIDC providers cho EKS và GitHub Actions.

## 6. RDS và quản lý password

RDS PostgreSQL được tạo bằng Terraform trong private database subnet.

Project không lưu raw database password trong repository.

Do account hiện tại chưa có quyền tạo secret trong AWS Secrets Manager, project đang dùng Terraform random_password cho môi trường dev.

Ý nghĩa của cách làm này:

1. Không cần nhập TF_VAR_rds_password thủ công khi chạy Terraform.

2. Không hardcode password vào file tfvars hoặc source code.

3. Password được lưu trong Terraform state S3 dưới dạng sensitive state.

Đây là lựa chọn phù hợp cho mock và dev. Nếu triển khai production thật, nên chuyển sang RDS managed master password bằng Secrets Manager.

## 7. GitOps và Argo CD

Root app dev:

```text
gitops/argocd/root-app-dev.yaml
```

Root app trỏ đến:

```text
gitops/envs/dev
```

Các application chính:

1. hungnm-de000155-dev-root.

2. hungnm-de000155-dev-platform.

3. hungnm-de000155-dev-applications.

4. aws-load-balancer-controller.

5. metrics-server.

6. monitoring.

7. loki.

Trạng thái kỳ vọng khi kiểm tra:

```text
SYNC STATUS: Synced
HEALTH STATUS: Healthy
```

Lệnh kiểm tra:

```powershell
kubectl get applications -n argocd
```

## 8. Ứng dụng frontend và backend

Backend nằm tại:

```text
apps/backend
```

Frontend nằm tại:

```text
apps/frontend
```

Backend là Node.js HTTP API không dùng package dependency ngoài.

Frontend là static website chạy bằng Nginx.

Ingress route:

```text
/api -> backend service
/    -> frontend service
```

Các endpoint backend chính:

```text
GET  /
GET  /api/health
GET  /api/status
GET  /api/items
POST /api/events
GET  /healthz
```

Frontend có thao tác gửi demo event đến backend qua:

```text
POST /api/events
```

Luồng này chứng minh frontend gọi backend thật qua ALB, Ingress, Service và Pod.

## 9. GitHub Actions cho ứng dụng

Workflow:

```text
.github/workflows/app-dev.yml
```

Trigger chính:

```text
Push vào branch main khi có thay đổi trong apps
Manual dispatch
```

IAM role sử dụng:

```text
arn:aws:iam::296725355870:role/hungnm-de000155-dev-github-actions-app-ci
```

Workflow thực hiện:

1. Checkout source code.

2. Assume AWS IAM role bằng GitHub OIDC.

3. Login Amazon ECR.

4. Build backend image.

5. Push backend image lên ECR.

6. Build frontend image.

7. Push frontend image lên ECR.

8. Cập nhật image tag trong GitOps manifests.

9. Commit manifest thay đổi về GitHub.

10. Argo CD phát hiện commit mới và rollout ứng dụng.

Workflow không dùng AWS static access key.

## 10. GitHub Actions cho Terraform

Workflow:

```text
.github/workflows/terraform.yml
```

IAM role sử dụng:

```text
arn:aws:iam::296725355870:role/hungnm-de000155-dev-github-actions-terraform
```

Workflow được chia thành hai job:

1. validate.

2. plan-apply.

Job validate:

```text
Chạy trên pull_request, push main và workflow_dispatch.
Không dùng AWS credential.
Chạy terraform init -backend=false.
Chạy terraform fmt -check -recursive.
Chạy terraform validate.
```

Job plan-apply:

```text
Không chạy trên pull_request.
Chạy trên push main hoặc workflow_dispatch.
Dùng GitHub OIDC để assume IAM role.
Chạy terraform init với S3 backend.
Chạy terraform plan.
Chỉ apply khi workflow_dispatch và apply=true.
```

Mục tiêu của workflow này là kiểm soát hạ tầng qua GitHub Actions mà không dùng AWS static key.

## 11. Monitoring và logging

Platform add-ons được quản lý bằng Argo CD:

1. Metrics Server.

2. kube-prometheus-stack.

3. Grafana.

4. Alertmanager.

5. Loki.

6. Promtail.

Kiểm tra metrics:

```powershell
kubectl top nodes
kubectl top pods -A
```

Kiểm tra log backend:

```powershell
kubectl logs -n mock-app deploy/backend --tail=50
```

Khi gửi event từ frontend hoặc gọi API, backend ghi JSON log ra stdout để Promtail có dữ liệu ship về Loki.

## 12. Kiểm tra nhanh khi demo

1. Kiểm tra Argo CD:

```powershell
kubectl get applications -n argocd
```

2. Kiểm tra pod ứng dụng:

```powershell
kubectl get pods -n mock-app
```

3. Kiểm tra image đang chạy:

```powershell
kubectl get deploy -n mock-app backend frontend -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas
```

4. Kiểm tra Ingress và ALB:

```powershell
kubectl get ingress -n mock-app
```

5. Kiểm tra backend health:

```powershell
curl http://k8s-mockapp-mockapp-350f2d5889-1668082414.ap-southeast-1.elb.amazonaws.com/api/health
```

6. Gửi event test:

```powershell
curl -X POST http://k8s-mockapp-mockapp-350f2d5889-1668082414.ap-southeast-1.elb.amazonaws.com/api/events -H "Content-Type: application/json" -d "{\"source\":\"manual-demo\",\"action\":\"button-click\"}"
```

7. Kiểm tra Terraform state sạch:

```powershell
cd infra
terraform plan "-var-file=dev.terraform.tfvars"
```

Kết quả kỳ vọng:

```text
No changes. Your infrastructure matches the configuration.
```

## 13. Bảo mật và thông tin nhạy cảm

Project không lưu các thông tin sau trong repository:

1. AWS access key.

2. AWS secret key.

3. RDS raw password.

4. Terraform state.

5. File env local.

GitHub Actions truy cập AWS bằng OIDC và IAM role ngắn hạn.

RDS password cho dev được Terraform sinh bằng random_password và lưu trong remote state.

README_Progress.md là file checkpoint private local, không dùng làm tài liệu public-facing.

## 14. Phạm vi không triển khai trong deadline

Các phần sau được xem là mở rộng, không phải điều kiện hoàn thành hiện tại:

1. Production environment.

2. Karpenter.

3. HTTPS bằng Route53 và ACM.

4. Backend kết nối database thật và migration schema.

5. IAM policy tối ưu chi tiết cho production.

Lý do bỏ qua prod environment:

```text
Dev đã chứng minh đầy đủ luồng IaC, CI/CD, GitOps, EKS runtime, ALB, monitoring và logging.
Prod sẽ cần thêm thời gian cho tfvars, backend state, GitOps env, IAM boundary, domain, secret strategy và kiểm thử riêng.
Với deadline hiện tại, hoàn thiện dev end-to-end có giá trị thực tế hơn mở thêm prod nhưng chưa đủ kiểm chứng.
```

## 15. Chi phí và cleanup

Các tài nguyên AWS có thể phát sinh chi phí đáng chú ý:

1. EKS cluster.

2. EC2 worker nodes.

3. NAT Gateway.

4. Application Load Balancer.

5. RDS PostgreSQL.

6. ECR image storage.

Trước khi dừng project dài ngày, cần cân nhắc destroy hoặc scale down tài nguyên dev.

Lệnh kiểm tra trước khi destroy:

```powershell
cd infra
terraform plan "-var-file=dev.terraform.tfvars" -destroy
```

Chỉ chạy destroy khi đã chắc chắn không cần demo tiếp.

## 16. Kết luận

Project hiện đã đạt mục tiêu chính của một mock EKS GitOps platform cho deadline:

1. Có hạ tầng AWS bằng Terraform.

2. Có EKS cluster chạy workload thật.

3. Có frontend và backend deploy qua GitOps.

4. Có GitHub Actions build, push image và cập nhật manifest.

5. Có Argo CD reconcile desired state.

6. Có ALB expose ứng dụng.

7. Có monitoring và logging stack.

8. Có Terraform workflow dùng GitHub OIDC.

Trọng tâm tiếp theo là commit, push, xác nhận GitHub Actions chạy thành công và thực hiện checklist demo cuối cùng.
