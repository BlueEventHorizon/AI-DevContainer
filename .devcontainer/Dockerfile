FROM node:24-alpine

# workspace ディレクトリを作成して node ユーザーの所有にする
RUN mkdir -p /workspace && chown -R node:node /workspace

WORKDIR /workspace

# node ユーザーに切り替え
USER node

# package.json を node ユーザー所有でコピー
COPY --chown=node:node package*.json ./
