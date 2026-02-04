import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { ItemsModule } from "./items/items.module";

@Module({
    imports: [
        ConfigModule.forRoot(),
        TypeOrmModule.forRootAsync({
            imports: [ConfigModule],
            inject: [ConfigService],
            useFactory: (config: ConfigService) => ({
                type: "mysql",
                host: config.get("DB_HOST", "localhost"),
                port: config.get<number>("DB_PORT", 3306),
                username: config.get("DB_USERNAME", "root"),
                password: config.get("DB_PASSWORD"),
                database: config.get("DB_DATABASE", "test"),
                autoLoadEntities: true,
                synchronize: true,
            }),
        }),
        ItemsModule,
    ],
})
export class AppModule {}
