const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
require("dotenv").config({
    path: path.resolve(__dirname, "..", "infra", "environments", "dev", ".env"),
});

const isBootstrap = process.argv.includes("--bootstrap");
const args = process.argv
    .slice(2)
    .filter((a) => a !== "--bootstrap")
    .join(" ");

const bootstrapDir = path.resolve(__dirname, "..", "infra", "bootstrap");
const devDir = path.resolve(__dirname, "..", "infra", "environments", "dev");

const cwd = isBootstrap ? bootstrapDir : devDir;

// terraform.tfvars 파싱
function parseTfvars(filePath) {
    if (!fs.existsSync(filePath)) {
        throw new Error(`${filePath} 파일이 존재하지 않습니다.`);
    }
    const content = fs.readFileSync(filePath, "utf8");
    const vars = {};
    for (const match of content.matchAll(/(\w+)\s*=\s*"(.+?)"/g)) {
        vars[match[1]] = match[2];
    }
    return vars;
}

const tfvars = parseTfvars(path.join(devDir, "terraform.tfvars"));

function run(cmd, dir) {
    execSync(cmd, { cwd: dir, stdio: "inherit" });
}

try {
    // init 명령이고 bootstrap 모드가 아닐 때, bootstrap이 안 되어있으면 자동 실행
    if (args.startsWith("init") && !isBootstrap) {
        if (!fs.existsSync(path.join(bootstrapDir, ".terraform"))) {
            console.log("\n[bootstrap] S3 버킷/DynamoDB 테이블 초기화 중...\n");

            run("terraform init", bootstrapDir);

            try {
                run("terraform apply -auto-approve", bootstrapDir);
            } catch (e) {
                console.log("\n[bootstrap] 기존 리소스 감지 — import 시도 중...\n");

                if (!tfvars.project_name) {
                    throw new Error("project_name이 설정되지 않았습니다. terraform.tfvars를 확인하세요.");
                }
                const projectName = tfvars.project_name;

                const imports = [
                    ["aws_s3_bucket.tfstate", `${projectName}-tfstate`],
                    ["aws_s3_bucket_versioning.tfstate", `${projectName}-tfstate`],
                    ["aws_s3_bucket_server_side_encryption_configuration.tfstate", `${projectName}-tfstate`],
                    ["aws_s3_bucket_public_access_block.tfstate", `${projectName}-tfstate`],
                    ["aws_dynamodb_table.tflock", `${projectName}-tflock`],
                ];

                for (const [resource, id] of imports) {
                    try {
                        run(`terraform import ${resource} ${id}`, bootstrapDir);
                    } catch (_) {
                        // 이미 import 되었거나 존재하지 않는 경우 무시
                    }
                }

                run("terraform apply -auto-approve", bootstrapDir);
            }

            console.log("\n[bootstrap] 완료\n");
        }
    }

    run(`terraform ${args}`, cwd);
} catch (error) {
    process.exit(error.status ?? 1);
}
