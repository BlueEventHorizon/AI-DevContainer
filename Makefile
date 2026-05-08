.DEFAULT_GOAL := help
.PHONY: help setup start launch-sandbox update-tools update-all rebuild install uninstall detect-platform require-colima check-docker check-colima check-buildx fix-colima-locks

LAUNCH_SANDBOX_COMMAND := $(firstword $(MAKECMDGOALS))
LAUNCH_SANDBOX_ARGS := $(filter-out launch-sandbox,$(MAKECMDGOALS))
LAUNCH_SANDBOX_TARGET := $(if $(TARGET),$(TARGET),$(firstword $(LAUNCH_SANDBOX_ARGS)))

# 色定義
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# デフォルトターゲット: ヘルプを表示
help:
	@echo "Available targets:"
	@echo "  make setup      - Install Docker/Colima/Buildx environment"
	@echo "  make start      - Start Colima"
	@echo "  make launch-sandbox <path> [OPTIONS=\"--rebuild\"] - Launch AI Sandbox"
	@echo "  make update-tools - Update Claude Code and Codex in ai-sandbox image"
	@echo "  make update-all - Update full ai-sandbox image without cache"
	@echo "  make uninstall  - Uninstall all components"

# プラットフォーム検出
detect-platform:
	@if [ "$$(uname)" != "Darwin" ]; then \
		printf "$(RED)❌ Error: This Makefile is designed for macOS.$(RESET)\n"; \
		printf "$(RED)   Your platform: $$(uname)$(RESET)\n"; \
		exit 1; \
	fi
	@if ! command -v brew &>/dev/null; then \
		printf "$(RED)❌ Error: Homebrew is not installed.$(RESET)\n"; \
		printf "$(RED)   Install from: https://brew.sh$(RESET)\n"; \
		exit 1; \
	fi

# Colima/Lima の stale なディスクロックを検出・削除
# Mac のスリープ・強制再起動・クラッシュ後にロックが残り起動不能になる問題への対策
fix-colima-locks:
	@for lock in $(HOME)/.colima/_lima/_disks/*/in_use_by; do \
		[ -e "$$lock" ] || continue; \
		target=$$(readlink "$$lock" 2>/dev/null || true); \
		if [ -z "$$target" ]; then \
			printf "$(YELLOW)不正なロックを削除: $$lock$(RESET)\n"; \
			rm -f "$$lock"; \
			continue; \
		fi; \
		pid_file="$$target/pid"; \
		if [ ! -f "$$pid_file" ] || ! kill -0 $$(cat "$$pid_file" 2>/dev/null) 2>/dev/null; then \
			printf "$(YELLOW)Stale なロックを削除: $$lock$(RESET)\n"; \
			rm -f "$$lock"; \
		fi; \
	done

# メイン: Colima, Docker, Buildx のセットアップ
setup: detect-platform check-docker check-colima check-buildx
	@printf "$(YELLOW)✅ Setup complete!$(RESET)\n"
	@printf "$(YELLOW)Next: Run 'make start' to start Colima.$(RESET)\n"

# Colima を起動
start: detect-platform require-colima fix-colima-locks
	@printf "$(YELLOW)Starting Colima...$(RESET)\n"
	@if colima status &>/dev/null; then \
		printf "$(YELLOW)Colima is already running.$(RESET)\n"; \
	else \
		if colima start --memory 8; then \
			printf "$(YELLOW)Colima started successfully.$(RESET)\n"; \
		else \
			printf "$(RED)❌ Failed to start Colima.$(RESET)\n"; \
			exit 1; \
		fi; \
	fi
	@printf "$(YELLOW)✅ Colima is ready!$(RESET)\n"
	@printf "$(YELLOW)Next: Run 'make launch-sandbox /path/to/project' to launch AI Sandbox.$(RESET)\n"

# このリポジトリ直下から、ターゲットプロジェクトを指定して Sandbox を起動
launch-sandbox:
	@if [ -z "$(LAUNCH_SANDBOX_TARGET)" ]; then \
		printf "$(RED)❌ Target project path is required.$(RESET)\n"; \
		printf "$(YELLOW)Usage: make launch-sandbox /path/to/project [OPTIONS=\"--rebuild\"]$(RESET)\n"; \
		exit 1; \
	fi
	@./launch-sandbox.sh $(OPTIONS) "$(LAUNCH_SANDBOX_TARGET)"

# Claude Code / Codex の取得レイヤーだけを更新
update-tools:
	@printf "$(YELLOW)Updating Claude Code and Codex in ai-sandbox image...$(RESET)\n"
	@if docker build --build-arg AI_TOOLS_CACHE_BUST="$$(date +%s)" -t ai-sandbox .devcontainer/; then \
		printf "$(YELLOW)✅ Tool update complete!$(RESET)\n"; \
		printf "$(YELLOW)Next: Run 'make launch-sandbox /path/to/project' to launch AI Sandbox.$(RESET)\n"; \
	else \
		printf "$(RED)❌ Failed to update AI tools in ai-sandbox image.$(RESET)\n"; \
		exit 1; \
	fi

# 共有 Docker イメージをキャッシュなしで全更新
update-all:
	@printf "$(YELLOW)Updating full ai-sandbox image without cache...$(RESET)\n"
	@if docker build --no-cache -t ai-sandbox .devcontainer/; then \
		printf "$(YELLOW)✅ Full image update complete!$(RESET)\n"; \
		printf "$(YELLOW)Next: Run 'make launch-sandbox /path/to/project' to launch AI Sandbox.$(RESET)\n"; \
	else \
		printf "$(RED)❌ Failed to update full ai-sandbox image.$(RESET)\n"; \
		exit 1; \
	fi

# 旧コマンド名の互換エイリアス
rebuild:
	@printf "$(YELLOW)'make rebuild' has been renamed to 'make update-all'.$(RESET)\n"
	@$(MAKE) update-all

ifeq ($(LAUNCH_SANDBOX_COMMAND),launch-sandbox)
ifneq ($(LAUNCH_SANDBOX_ARGS),)
.PHONY: $(LAUNCH_SANDBOX_ARGS)
$(LAUNCH_SANDBOX_ARGS):
	@:
endif
endif

# 旧コマンドの誤用防止
install:
	@printf "$(RED)❌ 'make install' has been replaced.$(RESET)\n"
	@printf "$(YELLOW)Use 'make setup' for first-time setup, then 'make start' to start Colima.$(RESET)\n"
	@exit 1

# Docker がインストールされているかチェック
check-docker:
	@if ! command -v docker &>/dev/null; then \
		printf "$(YELLOW)Docker not found. Installing...$(RESET)\n"; \
		if brew install docker; then \
			printf "$(YELLOW)Docker installed successfully.$(RESET)\n"; \
		else \
			printf "$(RED)❌ Failed to install Docker.$(RESET)\n"; \
			exit 1; \
		fi; \
	else \
		printf "$(YELLOW)Docker is already installed.$(RESET)\n"; \
	fi

# Colima が存在するかチェック（start 用。未インストールなら setup を案内）
require-colima:
	@if ! command -v colima &>/dev/null; then \
		printf "$(RED)❌ Colima is not installed.$(RESET)\n"; \
		printf "$(YELLOW)Run 'make setup' first.$(RESET)\n"; \
		exit 1; \
	fi

# Colima がインストールされているかチェック
check-colima:
	@if ! command -v colima &>/dev/null; then \
		printf "$(YELLOW)Colima not found. Installing...$(RESET)\n"; \
		if brew install colima; then \
			printf "$(YELLOW)Colima installed successfully.$(RESET)\n"; \
		else \
			printf "$(RED)❌ Failed to install Colima.$(RESET)\n"; \
			exit 1; \
		fi; \
	else \
		printf "$(YELLOW)Colima is already installed.$(RESET)\n"; \
	fi

# Buildx プラグインが存在するかチェック（アーキテクチャ自動検出）
check-buildx:
	@if [ ! -f "$$HOME/.docker/cli-plugins/docker-buildx" ]; then \
		printf "$(YELLOW)Docker buildx not found. Installing...$(RESET)\n"; \
		mkdir -p "$$HOME/.docker/cli-plugins"; \
		ARCH=$$(uname -m); \
		case $$ARCH in \
			x86_64) BUILDX_ARCH="darwin-amd64" ;; \
			arm64|aarch64) BUILDX_ARCH="darwin-arm64" ;; \
			*) printf "$(RED)❌ Unsupported architecture: $$ARCH$(RESET)\n"; exit 1 ;; \
		esac; \
		printf "$(YELLOW)Detected architecture: $$ARCH ($$BUILDX_ARCH)$(RESET)\n"; \
		LATEST_VERSION=$$(curl -fsSL https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.26.1"); \
		printf "$(YELLOW)Downloading buildx v$$LATEST_VERSION...$(RESET)\n"; \
		TMP_FILE=$$(mktemp); \
		if curl -fLo "$$TMP_FILE" "https://github.com/docker/buildx/releases/download/v$$LATEST_VERSION/buildx-v$$LATEST_VERSION.$$BUILDX_ARCH"; then \
			mv "$$TMP_FILE" "$$HOME/.docker/cli-plugins/docker-buildx" && \
			chmod +x "$$HOME/.docker/cli-plugins/docker-buildx" && \
			printf "$(YELLOW)Docker buildx installed successfully.$(RESET)\n"; \
		else \
			printf "$(RED)❌ Failed to download buildx. Please check your internet connection.$(RESET)\n"; \
			rm -f "$$TMP_FILE"; \
			exit 1; \
		fi; \
	else \
		printf "$(YELLOW)Docker buildx is already installed.$(RESET)\n"; \
	fi

# すべてをアンインストール
uninstall:
	@if command -v colima &>/dev/null; then \
		printf "$(YELLOW)Uninstalling Colima...$(RESET)\n"; \
		colima stop 2>/dev/null || true; \
		colima delete 2>/dev/null || true; \
		brew uninstall colima || true; \
		printf "$(YELLOW)Removing Colima data...$(RESET)\n"; \
		rm -rf ~/.colima 2>/dev/null || true; \
		printf "$(YELLOW)Colima uninstalled.$(RESET)\n"; \
	else \
		printf "$(YELLOW)Colima is not installed.$(RESET)\n"; \
	fi
	@if [ -f "$$HOME/.docker/cli-plugins/docker-buildx" ]; then \
		printf "$(YELLOW)Removing Docker buildx plugin...$(RESET)\n"; \
		rm -f "$$HOME/.docker/cli-plugins/docker-buildx"; \
		printf "$(YELLOW)Docker buildx uninstalled.$(RESET)\n"; \
	else \
		printf "$(YELLOW)Docker buildx plugin is not installed.$(RESET)\n"; \
	fi
	@if command -v docker &>/dev/null; then \
		printf "$(YELLOW)Uninstalling Docker...$(RESET)\n"; \
		brew uninstall docker || true; \
		printf "$(YELLOW)Docker uninstalled.$(RESET)\n"; \
	else \
		printf "$(YELLOW)Docker is not installed.$(RESET)\n"; \
	fi
	@printf "$(YELLOW)All components have been uninstalled.$(RESET)\n"
