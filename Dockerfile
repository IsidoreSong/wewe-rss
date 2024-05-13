# 使用Node.js的Alpine Linux版本作为基础镜像
FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# 全局安装pnpm
RUN npm i -g pnpm

# 创建一个新的构建阶段，克隆GitHub仓库
FROM base AS clone
WORKDIR /usr/src/app
RUN apk add --no-cache git
RUN git clone https://github.com/cooderl/wewe-rss.git .

# 构建应用
FROM base AS build
COPY --from=clone /usr/src/app /usr/src/app
WORKDIR /usr/src/app

# 使用pnpm安装依赖，构建应用
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run -r build

# 部署命令调整为使用克隆的代码
RUN pnpm deploy --filter=server --prod /app
RUN pnpm deploy --filter=server --prod /app-sqlite

# 生成Prisma客户端
RUN cd /app && pnpm exec prisma generate
RUN cd /app-sqlite && rm -rf ./prisma && mv prisma-sqlite prisma && pnpm exec prisma generate


WORKDIR /app
EXPOSE 4000
# 环境变量设置
ENV NODE_ENV=production
ENV HOST="0.0.0.0"
ENV SERVER_ORIGIN_URL=""
ENV MAX_REQUEST_PER_MINUTE=60
ENV AUTH_CODE=""
ENV DATABASE_URL=""
ENV CRON_EXPRESSION=""
RUN chmod +x ./docker-bootstrap.sh
CMD ["./docker-bootstrap.sh"]

# 定义最终使用的app阶段
FROM base AS app
COPY --from=build /app /app
WORKDIR /app
EXPOSE 4000
# 环境变量设置
ENV NODE_ENV=production
ENV HOST="0.0.0.0"
ENV SERVER_ORIGIN_URL=""
ENV MAX_REQUEST_PER_MINUTE=60
ENV AUTH_CODE=""
ENV DATABASE_URL=""
ENV CRON_EXPRESSION="0 8 * * *"
RUN chmod +x ./docker-bootstrap.sh
CMD ["./docker-bootstrap.sh"]
