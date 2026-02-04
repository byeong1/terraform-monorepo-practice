# SSH 키 페어
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.public_key
}

# EC2 인스턴스 - Docker Compose 기반 앱 서버
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
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

# 앱 디렉토리 생성
mkdir -p /home/ec2-user/app/frontend/src
mkdir -p /home/ec2-user/app/backend/src

# docker-compose.yml
cat > /home/ec2-user/app/docker-compose.yml << 'COMPOSE'
services:
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DB_HOST: ${var.db_host}
      DB_PORT: 3306
      DB_USERNAME: ${var.db_username}
      DB_PASSWORD: ${var.db_password}
      DB_DATABASE: ${var.db_name}

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
COMPOSE

# Root package.json (yarn workspace)
cat > /home/ec2-user/app/package.json << 'ROOTPKG'
{
  "name": "app",
  "private": true,
  "workspaces": [
    "frontend",
    "backend"
  ],
  "scripts": {
    "dev:frontend": "yarn workspace frontend dev",
    "dev:backend": "yarn workspace backend start:dev",
    "build:frontend": "yarn workspace frontend build",
    "build:backend": "yarn workspace backend build",
    "build": "yarn build:backend && yarn build:frontend",
    "start:prod": "yarn workspace backend start:prod"
  }
}
ROOTPKG

# Backend package.json
cat > /home/ec2-user/app/backend/package.json << 'BPKG'
{
  "name": "backend",
  "version": "1.0.0",
  "scripts": {
    "start:dev": "nest start --watch",
    "build": "nest build",
    "start:prod": "node dist/main"
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "typeorm": "^0.3.17",
    "mysql2": "^3.6.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.1",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "@nestjs/schematics": "^10.0.0",
    "typescript": "^5.1.0",
    "@types/node": "^20.0.0",
    "@types/express": "^4.17.0"
  }
}
BPKG

# Backend tsconfig.json
cat > /home/ec2-user/app/backend/tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": false,
    "noImplicitAny": false,
    "strictBindCallApply": false,
    "forceConsistentCasingInFileNames": false,
    "noFallthroughCasesInSwitch": false
  }
}
TSCONFIG

# Backend nest-cli.json
cat > /home/ec2-user/app/backend/nest-cli.json << 'NESTCLI'
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src"
}
NESTCLI

# Backend src/main.ts
cat > /home/ec2-user/app/backend/src/main.ts << 'MAIN'
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  await app.listen(3000);
}
bootstrap();
MAIN

# Backend src/app.module.ts
cat > /home/ec2-user/app/backend/src/app.module.ts << 'APPMOD'
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ItemsModule } from './items/items.module';
import { Item } from './items/item.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 3306,
      username: process.env.DB_USERNAME || 'root',
      password: process.env.DB_PASSWORD || 'password',
      database: process.env.DB_DATABASE || 'appdb',
      entities: [Item],
      synchronize: true,
    }),
    ItemsModule,
  ],
})
export class AppModule {}
APPMOD

# Backend src/items 디렉토리 및 entity
mkdir -p /home/ec2-user/app/backend/src/items
cat > /home/ec2-user/app/backend/src/items/item.entity.ts << 'ENTITY'
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity()
export class Item {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @CreateDateColumn()
  createdAt: Date;
}
ENTITY

# Backend src/items/items.module.ts
cat > /home/ec2-user/app/backend/src/items/items.module.ts << 'IMOD'
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ItemsController } from './items.controller';
import { ItemsService } from './items.service';
import { Item } from './item.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Item])],
  controllers: [ItemsController],
  providers: [ItemsService],
})
export class ItemsModule {}
IMOD

# Backend src/items/items.service.ts
cat > /home/ec2-user/app/backend/src/items/items.service.ts << 'ISVC'
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Item } from './item.entity';

@Injectable()
export class ItemsService {
  constructor(
    @InjectRepository(Item)
    private itemsRepository: Repository<Item>,
  ) {}

  findAll(): Promise<Item[]> {
    return this.itemsRepository.find({ order: { createdAt: 'DESC' } });
  }

  findOne(id: number): Promise<Item> {
    return this.itemsRepository.findOneBy({ id });
  }

  create(data: Partial<Item>): Promise<Item> {
    const item = this.itemsRepository.create(data);
    return this.itemsRepository.save(item);
  }

  async update(id: number, data: Partial<Item>): Promise<Item> {
    await this.itemsRepository.update(id, data);
    return this.itemsRepository.findOneBy({ id });
  }

  async remove(id: number): Promise<void> {
    await this.itemsRepository.delete(id);
  }
}
ISVC

# Backend src/items/items.controller.ts
cat > /home/ec2-user/app/backend/src/items/items.controller.ts << 'ICTRL'
import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { ItemsService } from './items.service';
import { Item } from './item.entity';

@Controller('items')
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Get()
  findAll(): Promise<Item[]> {
    return this.itemsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string): Promise<Item> {
    return this.itemsService.findOne(+id);
  }

  @Post()
  create(@Body() data: Partial<Item>): Promise<Item> {
    return this.itemsService.create(data);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() data: Partial<Item>): Promise<Item> {
    return this.itemsService.update(+id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string): Promise<void> {
    return this.itemsService.remove(+id);
  }
}
ICTRL

# Backend Dockerfile
cat > /home/ec2-user/app/backend/Dockerfile << 'BDOCK'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile || yarn install
COPY . .
RUN yarn build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
CMD ["yarn", "start:prod"]
BDOCK

# Frontend package.json
cat > /home/ec2-user/app/frontend/package.json << 'FPKG'
{
  "name": "frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.3.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.4.0",
    "vite": "^5.0.0"
  }
}
FPKG

# Frontend vite.config.js
cat > /home/ec2-user/app/frontend/vite.config.js << 'VCONF'
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
});
VCONF

# Frontend index.html
cat > /home/ec2-user/app/frontend/index.html << 'FHTML'
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Items App</title>
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/main.js"></script>
</body>
</html>
FHTML

# Frontend src/main.js
cat > /home/ec2-user/app/frontend/src/main.js << 'FMAIN'
import { createApp } from 'vue';
import App from './App.vue';

createApp(App).mount('#app');
FMAIN

# Frontend src/App.vue
cat > /home/ec2-user/app/frontend/src/App.vue << 'FAPP'
<template>
  <div style="max-width: 600px; margin: 40px auto; font-family: sans-serif;">
    <h1>Items CRUD</h1>

    <form @submit.prevent="addItem" style="margin-bottom: 20px;">
      <input v-model="newItem.name" placeholder="Name" required style="padding: 8px; margin-right: 8px;" />
      <input v-model="newItem.description" placeholder="Description" style="padding: 8px; margin-right: 8px;" />
      <button type="submit" style="padding: 8px 16px;">Add</button>
    </form>

    <div v-if="loading">Loading...</div>

    <ul style="list-style: none; padding: 0;">
      <li v-for="item in items" :key="item.id" style="padding: 12px; border: 1px solid #ddd; margin-bottom: 8px; border-radius: 4px; display: flex; justify-content: space-between; align-items: center;">
        <div>
          <strong>{{ item.name }}</strong>
          <span v-if="item.description"> - {{ item.description }}</span>
        </div>
        <button @click="deleteItem(item.id)" style="padding: 4px 12px; color: red; border: 1px solid red; background: white; border-radius: 4px; cursor: pointer;">Delete</button>
      </li>
    </ul>

    <p v-if="!loading && items.length === 0" style="color: #888;">No items yet.</p>
  </div>
</template>

<script>
export default {
  data() {
    return {
      items: [],
      newItem: { name: '', description: '' },
      loading: false,
    };
  },
  async mounted() {
    await this.fetchItems();
  },
  methods: {
    async fetchItems() {
      this.loading = true;
      try {
        const res = await fetch('/api/items');
        this.items = await res.json();
      } catch (e) {
        console.error(e);
      } finally {
        this.loading = false;
      }
    },
    async addItem() {
      try {
        await fetch('/api/items', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(this.newItem),
        });
        this.newItem = { name: '', description: '' };
        await this.fetchItems();
      } catch (e) {
        console.error(e);
      }
    },
    async deleteItem(id) {
      try {
        await fetch('/api/items/' + id, { method: 'DELETE' });
        await this.fetchItems();
      } catch (e) {
        console.error(e);
      }
    },
  },
};
</script>
FAPP

# Frontend nginx.conf
cat > /home/ec2-user/app/frontend/nginx.conf << 'NGINX'
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX

# Frontend Dockerfile
cat > /home/ec2-user/app/frontend/Dockerfile << 'FDOCK'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile || yarn install
COPY . .
RUN yarn build

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
FDOCK

# 소유권 변경 및 Docker Compose 실행
chown -R ec2-user:ec2-user /home/ec2-user/app
cd /home/ec2-user/app
docker-compose up -d --build
EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
