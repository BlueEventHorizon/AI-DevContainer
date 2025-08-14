> [!NOTE]
> このドキュメントは、Google の Gemini によって作成されました。

# VS Code DevContainer for Gemini CLI

このプロジェクトは、[Gemini CLI](https://www.npmjs.com/package/@google/gemini-cli) を [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers) 上で利用するためのサンプル環境です。
コンテナ技術を利用することで、ローカル環境を汚さずに、誰でも同じ開発環境を素早く構築できます。

## ✨ 主な特徴

- **環境構築済み:** Gemini CLI がプリインストールされた Node.js 環境が定義されています。
- **一貫性:** DevContainer を使うことで、OS の違い（macOS, Windows, Linux）を問わず、統一された環境で開発できます。
- **拡張機能の推奨:** Gemini を利用する上で便利な VS Code 拡張機能（`google.gemini-code-assist`）が推奨されます。

## 🛠️ セットアップ方法

### 前提条件

- [Visual Studio Code](https://code.visualstudio.com/)
- [DevContainers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) VS Code 拡張機能
- [Docker](https://www.docker.com/products/docker-desktop/) または互換性のあるコンテナ実行環境

---

### 🚀 起動手順

1.  **プロジェクトをクローンする**
    ```bash
    git clone https://github.com/mitsuharu/Sample-DevContainer.git
    cd Sample-DevContainer
    ```

2.  **Docker Desktop の代替 (macOS ユーザー向け)**
    Docker Desktop が利用できない、または利用したくない場合に、[Colima](https://github.com/abiosoft/colima) を利用して代替環境を構築できます。

    **初回セットアップ:**
    以下のコマンドは、必要なツール（Docker, Colima）のインストールと Colima の起動を一度に行います。初めて環境を構築する際に一度だけ実行してください。

    ```bash
    make setup-docker
    ```

    **2回目以降の起動と停止:**
    セットアップが完了している場合、開発作業の開始時に以下のコマンドで Colima を起動します。

    ```bash
    colima start
    ```

    作業が終了したら、以下のコマンドで Colima を停止してください。

    ```bash
    colima stop
    ```

3.  **DevContainer で開く**
    VS Code でこのプロジェクトフォルダを開くと、右下に「Reopen in Container」という通知が表示されます。これをクリックしてください。
    
    通知が表示されない場合は、コマンドパレット (`Ctrl+Shift+P` または `Cmd+Shift+P`) を開き、「`Dev Containers: Reopen in Container`」を実行します。

4.  **完了**
    コンテナのビルドが完了すると、VS Code がコンテナに接続された状態で再起動します。これでセットアップは完了です。

## 使い方

コンテナ環境の準備ができたら、VS Code 内で新しいターミナルを開きます。
以下のコマンドで Gemini CLI が利用できます。

```bash
# gemini コマンドの存在確認
gemini --help
```

`package.json` に定義された npm script を経由して実行することも可能です。

```bash
npm run gemini -- --help
```

## 📂 ファイル構成

- **`.devcontainer/`**: DevContainer の設定ファイルが含まれています。
  - `devcontainer.json`: ポート、拡張機能、ビルド方法などを定義します。
  - `Dockerfile`: コンテナのベースイメージと、インストールするソフトウェア（`@google/gemini-cli`）を定義します。
- **`package.json`**: プロジェクトの依存関係（`@google/gemini-cli`）と npm スクリプトを定義します。
- **`Makefile`**: (macOS ユーザー向け) Docker Desktop の代替として Colima をセットアップするためのヘルパーコマンドが定義されています。
- **`.vscode/`**: VS Code エディタに固有の設定が含まれています。
  - `extensions.json`: このプロジェクトで推奨される VS Code 拡張機能を定義します。