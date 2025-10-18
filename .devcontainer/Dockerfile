FROM node:24-alpine

# workspace ディレクトリを作成して node ユーザーの所有にする
RUN mkdir -p /workspace && chown -R node:node /workspace

WORKDIR /workspace

# node ユーザーに切り替え
USER node

# シェル設定にエイリアスとPATHを追加
RUN echo 'export PATH="./node_modules/.bin:$PATH"' >> ~/.profile && \
    echo 'alias ll="ls -la"' >> ~/.profile && \
    echo 'alias claude="npx claude"' >> ~/.profile && \
    echo 'alias gemini="npx gemini"' >> ~/.profile && \
    echo 'alias codex="npx codex"' >> ~/.profile

# package.json を node ユーザー所有でコピー
COPY --chown=node:node package*.json ./

# 依存関係をインストール
RUN npm install
