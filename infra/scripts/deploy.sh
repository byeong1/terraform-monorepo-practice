#!/bin/bash
set -e

# 인자 받기
REGION=$1
BACKEND_REPO=$2
FRONTEND_REPO=$3
APP_PATH=$4
EC2_IP=$5
SSH_KEY_PATH=$6

ECR_HOST=$(echo "$BACKEND_REPO" | cut -d'/' -f1)

# 0. Docker Daemon 실행 확인
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker Daemon이 실행되지 않았습니다. Docker Desktop을 시작해주세요."
  exit 1
fi

# 1. ECR 로그인
echo "=== ECR 로그인 ==="
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_HOST"

# 2. Backend 빌드 & push
echo "=== Backend 빌드 ==="
docker build -t "$BACKEND_REPO:latest" "$APP_PATH/backend"
echo "=== Backend push ==="
docker push "$BACKEND_REPO:latest"

# 3. Frontend 빌드 & push
echo "=== Frontend 빌드 ==="
docker build -t "$FRONTEND_REPO:latest" "$APP_PATH/frontend"
echo "=== Frontend push ==="
docker push "$FRONTEND_REPO:latest"

# 4. EC2에 SSH로 접속해서 pull & 재시작
# EC2가 새로 생성된 경우 user_data가 자동으로 처리하므로 건너뜀
echo "=== EC2 배포 ==="
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$SSH_KEY_PATH" ec2-user@"$EC2_IP" "test -d /home/ec2-user/app" 2>/dev/null; then
  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ec2-user@"$EC2_IP" \
    "cd /home/ec2-user/app && sudo docker-compose pull && sudo docker-compose up -d && sudo docker image prune -f"
  echo "=== 배포 완료 ==="
else
  echo "=== EC2가 초기화 중입니다. user_data가 자동으로 배포합니다. ==="
fi
