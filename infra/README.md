# Infrastructure

Deployment configuration is intentionally absent.

The architecture document targets AWS and leaves the application runtime as either App Runner or ECS Fargate. It also calls for RDS PostgreSQL, S3 for published images, a durable queue and worker for SMS and push, Secrets Manager or SSM Parameter Store, CloudWatch, and HTTPS. Those choices depend on an AWS account owner, region, and budget, which are still open.

This phase does not add Terraform, container manifests, Kubernetes, or live cloud resources.

When that decision is made, keep production secrets out of the repository and out of the Flutter app. The API already reads database credentials, the Django secret, allowed hosts, and browser origins from the environment.
