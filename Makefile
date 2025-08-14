.PHONY: setup-docker check-docker check-colima check-buildx install-docker install-colima install-buildx uninstall-docker uninstall-colima uninstall-buildx

# メイン: Colima, Docker, Buildx のセットアップ
setup-docker: check-docker check-colima check-buildx
   @echo "🟢 Starting Colima..."
   colima start
   @echo "🚀 You can launch up DevContainer with VS Code"
   code

# Docker がインストールされているかチェック
check-docker:
   @if ! command -v docker &>/dev/null; then \
       echo "🛠 Docker not found. Installing..."; \
       brew install docker; \
   else \
       echo "✅ Docker is already installed."; \
   fi

# Colima がインストールされているかチェック
check-colima:
   @if ! command -v colima &>/dev/null; then \
       echo "🛠 Colima not found. Installing..."; \
       brew install colima; \
   else \
       echo "✅ Colima is already installed."; \
   fi

# Buildx プラグインが存在するかチェック
check-buildx:
   @if [ ! -f "$$HOME/.docker/cli-plugins/docker-buildx" ]; then \
       echo "🛠 Docker buildx not found. Installing..."; \
       mkdir -p "$$HOME/.docker/cli-plugins"; \
       TMP_FILE=$$(mktemp); \
       curl -fLo "$$TMP_FILE" https://github.com/docker/buildx/releases/download/v0.26.1/buildx-v0.26.1.darwin-arm64 && \
       mv "$$TMP_FILE" "$$HOME/.docker/cli-plugins/docker-buildx" && \
       chmod +x "$$HOME/.docker/cli-plugins/docker-buildx"; \
   else \
       echo "✅ Docker buildx is already installed."; \
   fi

# Docker をアンインストール
uninstall-docker:
   @if command -v docker &>/dev/null; then \
       echo "🧹 Uninstalling Docker..."; \
       brew uninstall docker || true; \
   else \
       echo "ℹ️ Docker is not installed."; \
   fi

# Colima をアンインストール
uninstall-colima:
   @if command -v colima &>/dev/null; then \
       echo "🧹 Uninstalling Colima..."; \
       colima stop || true; \
       brew uninstall colima || true; \
   else \
       echo "ℹ️ Colima is not installed."; \
   fi

# Buildx プラグインをアンインストール
uninstall-buildx:
   @if [ -f "$$HOME/.docker/cli-plugins/docker-buildx" ]; then \
       echo "🧹 Removing Docker buildx plugin..."; \
       rm -f "$$HOME/.docker/cli-plugins/docker-buildx"; \
   else \
       echo "ℹ️ Docker buildx plugin is not installed."; \
   fi
