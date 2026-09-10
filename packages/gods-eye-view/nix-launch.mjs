#!/usr/bin/env node
import { spawn } from "node:child_process";
import {
  copyFileSync,
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const storeRoot = path.resolve(__dirname, "..");
const version = process.env.GEV_NIX_VERSION || "unknown";
const host = process.env.GEV_HOST || "127.0.0.1";
const port = process.env.GEV_PORT || "4173";
const xdgData =
  process.env.XDG_DATA_HOME || path.join(homedir(), ".local", "share");
const xdgConfig =
  process.env.XDG_CONFIG_HOME || path.join(homedir(), ".config");
const dataDir = path.join(xdgData, "gods-eye-view");
const appDir = path.join(dataDir, "app");
const stampPath = path.join(dataDir, ".nix-version");
const configEnv = path.join(xdgConfig, "gods-eye-view", ".env");

mkdirSync(dataDir, { recursive: true });
mkdirSync(path.dirname(configEnv), { recursive: true });

const stamped = existsSync(stampPath)
  ? readFileSync(stampPath, "utf8").trim()
  : "";
if (stamped !== version) {
  rmSync(appDir, { recursive: true, force: true });
  cpSync(storeRoot, appDir, { recursive: true });
  writeFileSync(stampPath, version + "\n");
}

if (existsSync(configEnv)) {
  copyFileSync(configEnv, path.join(appDir, ".env"));
} else if (!existsSync(path.join(appDir, ".env"))) {
  const example = path.join(appDir, ".env.example");
  if (existsSync(example)) copyFileSync(example, path.join(appDir, ".env"));
  else writeFileSync(path.join(appDir, ".env"), "");
}

const viteBin = path.join(appDir, "node_modules", "vite", "bin", "vite.js");
const child = spawn(
  process.execPath,
  [viteBin, "--host", host, "--port", String(port)],
  {
    cwd: appDir,
    env: {
      ...process.env,
      GEV_LAUNCHER: "nix",
    },
    stdio: "inherit",
  },
);

const openUrl = `http://${host === "0.0.0.0" ? "127.0.0.1" : host}:${port}`;
setTimeout(() => {
  spawn("xdg-open", [openUrl], {
    stdio: "ignore",
    detached: true,
  }).unref();
}, 1500);

const stop = (signal) => {
  if (!child.killed) child.kill(signal);
};
process.on("SIGINT", () => stop("SIGINT"));
process.on("SIGTERM", () => stop("SIGTERM"));
child.on("exit", (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code ?? 1);
});
