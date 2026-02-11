services:
  backend:
    image: ${backend_image}:latest
    ports:
      - "3000:3000"
    environment:
      DB_HOST: ${db_host}
      DB_PORT: "3306"
      DB_USERNAME: ${db_username}
      DB_PASSWORD: ${db_password}
      DB_DATABASE: ${db_name}
      AWS_REGION: ${region}
      MEDIA_BUCKET_NAME: ${media_bucket_name}
      CLOUDFRONT_DOMAIN: ${cloudfront_domain}
      CALLBACK_SECRET: ${callback_secret}

  frontend:
    image: ${frontend_image}:latest
    ports:
      - "80:80"
    depends_on:
      - backend
