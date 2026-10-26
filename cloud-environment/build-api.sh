#!/usr/bin/env bash
set -euo pipefail
cd /workspace/movie-env
python3 - <<'PY'
import pathlib, socket
host = socket.gethostbyname('proxy')
pathlib.Path('maven-settings.xml').write_text('<settings><mirrors><mirror><id>central-https</id><mirrorOf>*</mirrorOf><url>https://repo.maven.apache.org/maven2</url></mirror></mirrors><proxies><proxy><id>session</id><active>true</active><protocol>http</protocol><host>'+host+'</host><port>8080</port></proxy></proxies></settings>')
PY
docker run --rm -v /workspace/springboot-movie/api:/app -v /workspace/movie-env:/env -v /etc/ssl/certs/java/cacerts:/trust/cacerts:ro -w /app maven:3.9-eclipse-temurin-11 mvn -B -s /env/maven-settings.xml -Dmaven.repo.local=/env/m2 -Djavax.net.ssl.trustStore=/trust/cacerts verify
