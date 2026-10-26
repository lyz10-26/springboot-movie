#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$source_dir/.." && pwd)
if [ "$repo_dir" != /workspace/springboot-movie ]; then
  echo 'This setup expects the checkout at /workspace/springboot-movie.' >&2
  exit 1
fi

mkdir -p /workspace/movie-env
for name in install.sh start.sh build-api.sh prepare-frontends.py; do
  cp -- "$source_dir/$name" "/workspace/movie-env/$name"
done
bash /workspace/movie-env/install.sh
