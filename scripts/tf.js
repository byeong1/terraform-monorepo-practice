const { execSync } = require("child_process");
const path = require("path");
const dotenv = require("dotenv");

const cwd = path.resolve(__dirname, "..", "infra", "environments", "dev");
dotenv.config({ path: path.join(cwd, ".env") });

const args = process.argv.slice(2).join(" ");

try {
  execSync(`terraform ${args}`, { cwd, stdio: "inherit", env: { ...process.env } });
} catch (error) {
  process.exit(error.status ?? 1);
}
