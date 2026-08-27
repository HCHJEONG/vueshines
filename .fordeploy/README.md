# Vueshines Manual AWS Demo Deployment

The AWS demo deployment is deliberately manual. It builds a production-like
Spring Boot image containing the Vue production build, transfers the image
through the configured `aws-demo` SSH alias, and applies the AWS runtime with
Docker Compose.

## Required Local File

Create this file manually before deployment:

```text
<working-repository>/.fordeploy/aws-backup/.env
```

Use the repository root `.env.example` as the variable contract. The deploy
script never creates the real file, changes its local permissions, or prints
its contents. If the file is absent or a required value is empty, deployment
stops before cloning or building. File ownership and mode are applied only to
the transferred AWS copy.

## Build Source

The image is not built from the working tree. Each deployment completely
deletes and fresh-clones this dedicated path after explicit confirmation:

```text
/home/hchjeong/deploy-remote-repo/vueshines
```

Only committed and pushed changes can be deployed. The selected commit SHA is
included in the image tag and OCI image metadata.

## Deploy

```bash
.fordeploy/deploy-aws-demo.sh
```

Defaults:

```text
AWS SSH alias:       aws-demo
Remote app root:     /home/ubuntu/vueshines
Remote env file:     /home/ubuntu/vueshines/.env
Remote Compose file: /home/ubuntu/vueshines/compose.aws-demo.yaml
Remote image root:   /home/ubuntu/docker_images/vueshines
Application port:    8180 -> container 8080
Application URL:     https://vueshines.penvot.com
```

The script asks before transferring the env file and before deleting the clean
clone. The remote env file is installed as `ubuntu:ubuntu` with mode `600`.
The runtime directory uses mode `700`.

The script runs the committed `.fordeploy/compose.aws-demo.yaml` on AWS. MySQL
and Redis use explicitly named volumes, and a normal application redeploy runs
`docker compose up` without removing either volume.

On success, the script prints `DEPLOYMENT SUCCEEDED` with the commit, image,
target, and port. On failure, it prints the failed step and exit code. A remote
Compose failure also prints `compose ps -a` and the latest 150 log lines from
the application, MySQL, and Redis services without printing the env file.

## ALB And DNS

After the application responds on the AWS host, configure the existing ALB,
target group, security group ingress, and Route 53 alias:

```bash
.fordeploy/configure-aws-demo-alb.sh
```

This script changes AWS resources and therefore asks for confirmation. It uses
the `aws-bastion` SSH alias and `ap-northeast-2` by default.

## Verification

```bash
curl -i https://vueshines.penvot.com/api/health
curl -i https://vueshines.penvot.com/robots.txt
curl -i https://vueshines.penvot.com/about
```

The initial demo must return `X-Robots-Tag: noindex, nofollow, noarchive`, and
`robots.txt` must disallow all crawlers.
