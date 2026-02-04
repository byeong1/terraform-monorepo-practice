# Terraform Practice - AWS 인프라 & 앱 배포

## 아키텍처

```
VPC (10.0.0.0/16)
├── 퍼블릭 서브넷 (10.0.1.0/24) - ap-northeast-2a
│   └── EC2 (t2.micro)
│       └── Docker Compose
│           ├── Backend (NestJS)
│           └── Frontend (Vue + Nginx)
├── 프라이빗 서브넷 (10.0.10.0/24) - ap-northeast-2a
└── 프라이빗 서브넷 (10.0.11.0/24) - ap-northeast-2c
    └── RDS MySQL 8.0 (db.t3.micro)
```

- EC2에서 Docker Compose로 Backend/Frontend를 실행
- RDS는 프라이빗 서브넷에 배치, EC2에서만 접근 가능
- Frontend(Nginx)가 `/api/` 요청을 Backend로 프록시
    - / → Vue.js 정적 파일을 직접 제공 (HTML, JS, CSS)
    - /api/ → Backend(NestJS, 3000번 포트)로 요청을 대신 전달

## 프로젝트 구조

```
terraform/
├── app/                          # 애플리케이션 코드
│   ├── docker-compose.yml        # 로컬 Docker Compose (Backend + Frontend)
│   ├── backend/                  # NestJS Backend
│   │   └── .env.docker           # 로컬 Docker용 환경변수
│   └── frontend/                 # Vue.js Frontend
├── infra/                        # Terraform 인프라 코드
│   ├── modules/                  # 재사용 가능한 모듈
│   │   ├── vpc/                  # VPC, 서브넷, IGW, 라우트 테이블
│   │   ├── security/             # 보안그룹 (EC2용, DB용)
│   │   ├── rds/                  # RDS MySQL 인스턴스
│   │   └── ec2/                  # EC2 인스턴스 + user_data
│   └── environments/
│       └── dev/                  # 개발 환경 설정
│           ├── main.tf           # 모듈 조합
│           ├── variables.tf      # 환경 변수 정의
│           ├── outputs.tf        # 출력값 정의
│           ├── .env              # 환경변수 (git 미추적)
│           └── .env.example      # 환경변수 템플릿
├── scripts/
│   └── tf.js                     # .env 로드 후 Terraform 실행 래퍼
└── package.json                  # yarn 스크립트 정의
```

## 사전 준비

### 1. Terraform 설치

```bash
winget install HashiCorp.Terraform
```

설치 후 터미널을 재시작하여 PATH를 반영한다.

### 2. AWS IAM 설정

- IAM 사용자 생성 (`AdministratorAccess` 권한 그룹에 추가)
- 해당 사용자의 액세스 키 발급 (`Access Key ID`, `Secret Access Key`)

### 3. Node.js 및 Yarn 설치

Terraform 래퍼 스크립트(`scripts/tf.js`) 실행에 필요하다.

## 시작하기

### 1. 환경변수 설정

```bash
cp infra/environments/dev/.env.example infra/environments/dev/.env
```

`.env` 파일을 편집하여 실제 값을 입력:

```
TF_VAR_my_ip=YOUR_IP/32
TF_VAR_db_password=YOUR_DB_PASSWORD
TF_VAR_db_username=admin
TF_VAR_db_name=appdb
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY
```

### 2. 의존성 설치

```bash
yarn install
```

### 3. 인프라 배포

```bash
yarn infra:init     # Terraform 초기화 (최초 1회)
yarn infra:plan     # 변경사항 미리보기
yarn infra:apply    # 실제 인프라 생성
```

### 4. 인프라 삭제

```bash
yarn infra:destroy
```

## 사용 가능한 스크립트

| 스크립트             | 설명                                       |
| -------------------- | ------------------------------------------ |
| `yarn infra:init`    | Terraform 초기화 (Provider, 모듈 다운로드) |
| `yarn infra:plan`    | 인프라 변경사항 미리보기                   |
| `yarn infra:apply`   | 인프라 생성/변경 적용                      |
| `yarn infra:destroy` | 인프라 전체 삭제                           |

## 보안 구성

| 구성         | 설명                                             |
| ------------ | ------------------------------------------------ |
| EC2 보안그룹 | SSH(22)는 지정 IP만, HTTP(80)는 전체 허용        |
| DB 보안그룹  | MySQL(3306)은 EC2 보안그룹에서만 허용            |
| RDS          | 프라이빗 서브넷, 공개 접근 불가, 스토리지 암호화 |

## Terraform 기본 개념

### Provider

인프라 플랫폼과의 연결을 담당하는 플러그인이다.

```hcl
provider "aws" {
  region = "ap-northeast-2"
}
```

### Resource

실제로 생성할 인프라 구성요소다. (EC2, S3, VPC 등)

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### State (상태 파일)

- `terraform.tfstate` 파일에 현재 인프라의 상태를 JSON으로 저장한다
- Terraform은 이 파일을 기준으로 **실제 인프라와의 차이**를 계산한다
- 팀 작업 시 S3 등 원격 백엔드에 저장하는 것이 일반적이다

### Variable & Output

```hcl
# 입력 변수
variable "instance_type" {
  default = "t2.micro"
}

# 출력값
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

### Module

재사용 가능한 Terraform 코드 묶음이다. 디렉토리 단위로 구성한다.

### 워크플로우

```
terraform init  →  terraform plan  →  terraform apply  →  terraform destroy
```

| 명령어    | 역할                                           |
| --------- | ---------------------------------------------- |
| `init`    | Provider 플러그인/모듈 다운로드 (최초 1회)     |
| `plan`    | 코드와 상태 파일 비교, 변경 미리보기 (dry-run) |
| `apply`   | 변경사항을 실제 인프라에 적용                  |
| `destroy` | 상태 파일에 기록된 모든 리소스 삭제            |

핵심은 **선언적(Declarative)** 방식이라는 것이다. "이렇게 해라"가 아니라 **"이런 상태여야 한다"**를 선언하면, Terraform이 현재 상태와 비교해서 필요한 작업을 알아서 수행한다.
