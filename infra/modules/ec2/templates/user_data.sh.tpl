#!/bin/bash
set -ex

# Docker 설치
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Docker Compose 설치
DOCKER_COMPOSE_VERSION="v2.24.0"
curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# ECR 로그인
ACCOUNT_URL=$(echo "${backend_image}" | cut -d'/' -f1)
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin $${ACCOUNT_URL}

# 앱 디렉토리 생성
mkdir -p /home/ec2-user/app

# docker-compose.yml 생성
cat > /home/ec2-user/app/docker-compose.yml << 'COMPOSE'
${compose_content}
COMPOSE

chown -R ec2-user:ec2-user /home/ec2-user/app
cd /home/ec2-user/app
docker-compose pull
docker-compose up -d
