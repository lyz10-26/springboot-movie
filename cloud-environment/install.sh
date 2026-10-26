#!/usr/bin/env bash
set -euo pipefail
cd /workspace/movie-env
mkdir -p logs
env -u DOCKER_HOST -u DOCKER_CONTEXT -u DOCKER_TLS -u DOCKER_TLS_VERIFY -u DOCKER_CERT_PATH docker --host=unix:///var/run/docker.sock info >/dev/null
for image in mariadb:10.11 redis:7-alpine maven:3.9-eclipse-temurin-11; do
  docker image inspect "$image" >/dev/null 2>&1 || docker pull "$image"
done
python3 prepare-frontends.py
for name in app admin worker; do
  (
    cd "vue-$name"
    npm ci --cache /workspace/movie-env/npm-cache --registry=https://registry.npmjs.org --ignore-scripts --no-audit --no-fund
    NODE_OPTIONS=--openssl-legacy-provider npm run build -- --dest "/workspace/movie-env/dist-$name"
  ) >"logs/install-$name.log" 2>&1
done
bash build-api.sh >logs/maven.log 2>&1
echo 'Dependency installation and all builds passed. Start services with bash /workspace/movie-env/start.sh.'
