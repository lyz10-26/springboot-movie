# 云开发环境

这些脚本用于在 Codex 托管云环境中复现已验证的开发环境。使用已有检出目录 `/workspace/springboot-movie`；每个云任务已经隔离，无需新建 Git worktree。

## 安装与启动

依赖托管的本机 Docker daemon、Node.js/npm、Python 3、curl、ripgrep，以及环境提供的代理 `proxy:8080` 和 Java CA 信任库 `/etc/ssl/certs/java/cacerts`。这些脚本依赖托管环境，不是通用服务器部署脚本。

首次安装或需要重新安装依赖时执行：

```bash
bash /workspace/springboot-movie/cloud-environment/setup.sh
```

安装脚本将助手文件复制到 `/workspace/movie-env`，安装三个前端的依赖、构建前端，并使用 Java 11/Maven 容器构建后端。耗时步骤的输出写入 `/workspace/movie-env/logs`。

启动或恢复服务：

```bash
bash /workspace/movie-env/start.sh
```

服务进程不一定随环境快照恢复；每次恢复环境后执行启动脚本。脚本会启动数据库、Redis、后端和三个前端，并检查电影 API 和前端页面。

| 服务 | 云环境内部端口 |
| --- | --- |
| Spring Boot API | 8888 |
| 用户前端 | 8080 |
| 管理前端 | 8081 |
| 客服前端 | 8082 |
| MariaDB 10.11 | 3306 |
| Redis 7 | 6379 |

这些服务只绑定云环境的 `127.0.0.1`。提交到 GitHub 或发布开发环境不会生成公网网站地址，也无法通过自己电脑的 localhost 访问云内服务。需要浏览器外部访问时，应另行配置应用部署和访问入口。

## 日常开发

在原仓库的 `api`、`vue-app/src`、`vue-admin/src` 和 `vue-worker/src` 中修改源码。前端助手目录通过符号链接引用源码，并关闭 webpack 的符号链接解析，因此开发服务器会监听源码改动。

后端改动后执行：

```bash
bash /workspace/movie-env/build-api.sh
docker restart movie-api
bash /workspace/movie-env/start.sh
```

前端需要单独构建时，在对应助手目录执行，例如：

```bash
cd /workspace/movie-env/vue-app
NODE_OPTIONS=--openssl-legacy-provider npm run build -- --dest /workspace/movie-env/dist-app
```

仓库内提交的 `node_modules` 不完整。请在 `/workspace/movie-env/vue-*` 中运行依赖和构建命令，避免直接在仓库的前端目录运行 `npm ci`。助手仅转换锁文件副本中的旧淘宝 tarball 下载地址，保留版本与完整性校验，不修改仓库锁文件。webpack 4 在当前 Node 运行时需要 `--openssl-legacy-provider`。

重装依赖前，先停止本次任务启动的前端进程；PID 记录在 `/workspace/movie-env/{app,admin,worker}.pid`，停止前应确认对应进程仍属于该前端。不要停止其他任务的服务。

## 数据与配置

- 数据库数据保存在 `/workspace/movie-env/db`。仅在缺少 `t_film` 表时导入仓库的 `movie.sql`，避免重复导入覆盖已有开发数据。初始数据包含 12 部电影。
- 数据库使用空密码 root，仅用于隔离的本地开发；对外部署时需要独立的数据库账号与凭据配置。
- 后端数据库和 Redis 地址通过容器环境变量覆盖，仓库的 `application.yml` 保持不变。
- Maven 使用 HTTPS Maven Central、运行时解析的代理地址和系统 Java CA，保留 TLS 验证。
- 数据库、依赖缓存、构建产物、日志、PID、生成的 Maven 配置和请求响应均留在 `/workspace/movie-env`，无需提交到 GitHub。

## 已验证范围

后端 `mvn verify`、三个前端的生产构建和服务停止后的重新启动均已通过。浏览器检查确认用户首页显示 12 部电影、31 张图片加载成功，未发现页面运行错误；电影列表、详情和海报下载也已通过检查。

仓库没有自动化测试，上述构建和功能检查不能替代完整的购票、支付或权限测试。
