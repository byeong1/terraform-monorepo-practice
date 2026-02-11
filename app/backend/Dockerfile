FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g @nestjs/cli
COPY package.json ./
RUN yarn install
COPY . .
RUN nest build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
CMD ["node", "dist/main.js"]
