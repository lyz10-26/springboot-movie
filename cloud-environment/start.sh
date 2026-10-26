#!/usr/bin/env bash
set -euo pipefail
cd /workspace/movie-env
mkdir -p logs
docker network inspect movie-dev >/dev/null 2>&1 || docker network create movie-dev
if ! docker container inspect movie-db >/dev/null 2>&1; then
  docker run -d --name movie-db --network movie-dev -p 127.0.0.1:3306:3306 -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 -e MARIADB_DATABASE=movie -v /workspace/movie-env/db:/var/lib/mysql mariadb:10.11
else
  docker start movie-db >/dev/null
fi
ready=0
for i in {1..60}; do
  if docker exec movie-db mariadb-admin ping --silent >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
test "$ready" = 1
tables=$(docker exec movie-db mariadb -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='movie' AND table_name='t_film'")
if [ "$tables" = 0 ]; then
  docker exec -i movie-db mariadb movie < /workspace/springboot-movie/movie.sql
fi
if ! docker container inspect movie-redis >/dev/null 2>&1; then
  docker run -d --name movie-redis --network movie-dev -p 127.0.0.1:6379:6379 redis:7-alpine
else
  docker start movie-redis >/dev/null
fi
if ! docker container inspect movie-api >/dev/null 2>&1; then
  docker run -d --name movie-api --network movie-dev -p 127.0.0.1:8888:8888 -v /workspace/springboot-movie/api/target:/app:ro -e SPRING_DATASOURCE_URL='jdbc:mysql://movie-db:3306/movie?characterEncoding=utf8&serverTimezone=UTC' -e SPRING_DATASOURCE_USERNAME=root -e SPRING_DATASOURCE_PASSWORD= -e SPRING_REDIS_HOST=movie-redis maven:3.9-eclipse-temurin-11 java -jar /app/api-0.0.1-SNAPSHOT.jar
else
  docker start movie-api >/dev/null
fi
ready=0
for i in {1..60}; do
  if curl -fsS http://127.0.0.1:8888/api/film -o films.json 2>/dev/null && python3 -c 'import json; x=json.load(open("films.json")); assert x["success"] and x["code"] == 200 and x["data"] and x["data"][0].get("name")' 2>/dev/null; then ready=1; break; fi
  sleep 1
done
test "$ready" = 1 || { docker logs --tail 80 movie-api; exit 1; }
docker exec movie-redis redis-cli ping
for entry in app:8080 admin:8081 worker:8082; do
  name=${entry%:*}; port=${entry#*:}
  if ! curl -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1; then
    (cd "vue-$name"; nohup env NODE_OPTIONS=--openssl-legacy-provider node node_modules/@vue/cli-service/bin/vue-cli-service.js serve --host 127.0.0.1 --port "$port" >"/workspace/movie-env/logs/serve-$name.log" 2>&1 </dev/null & echo $! >"/workspace/movie-env/$name.pid")
  fi
  ready=0
  for i in {1..60}; do
    if curl -fsS "http://127.0.0.1:$port/" -o "page-$name.html" 2>/dev/null && rg -q 'id="app"' "page-$name.html"; then ready=1; break; fi
    sleep 1
  done
  test "$ready" = 1 || { tail -80 "logs/serve-$name.log"; exit 1; }
done
echo 'API, database, Redis and all three frontend development servers passed readiness checks.'
