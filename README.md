
- [概要](#概要)
  - [動作環境](#動作環境)
- [使い方](#使い方)
  - [INSTALL](#install)
  - [作業場所](#作業場所)
  - [コンパイル](#コンパイル)
  - [textlint](#textlint)
    - [ターミナルで実行](#ターミナルで実行)
    - [VScode上でlintを表示させる場合](#vscode上でlintを表示させる場合)
    - [研のlintルール](#研のlintルール)
  - [画像の貼り方](#画像の貼り方)
    - [png](#png)
    - [svg](#svg)
- [コマンド一覧](#コマンド一覧)
  - [LaTexのコンパイル](#latexのコンパイル)
  - [サンプルのコンパイル](#サンプルのコンパイル)
  - [TextLint](#textlint-1)
  - [dockerのリソースを開放](#dockerのリソースを開放)
  - [コンテナのパッケージ更新](#コンテナのパッケージ更新)
  - [Dockerのインストール](#dockerのインストール)

# 概要
* LaTeX環境をローカルにインストールしたくないので作りました
## 動作環境
* 実行環境
  * Docker
  * make
  * VScode
    * あると便利
    * 無くてもターミナルから実行可能
* VScodeの拡張機能
  * LaTeX-Workshop
    * LaTeXの補完
    * 保存時に自動コンパイル
  * Remote Development
    * VScode上にTextLintのエラーを表示させる

# 使い方
## INSTALL
* workspaceディレクトリの作成
* 環境をインストール
  * **Ubuntuのみ**Docker環境をインストールできる
    * Mac OS, Windowsは個別にDockerとmakeの実行環境を作ってください
    * インストール後に再起動が必要
  ```
  make install
  ```

* Dockerのビルド
  * インストールした後にDockerFileをビルドすることが必要
  * 所要時間：5~10分（ネットワークの速度依存）
  * 5GBのイメージを作るので時間がかかる
  ```
  make build
  ```

## 作業場所
* **workspace**内で.texファイルを作成
  * workspace内のファイルはGitの追跡対象外
  * サンプルコードは**sample**内のsemi.tex

## コンパイル
* コマンドから実行
  ```
  make run
  ```
* VSCode上で実行
  * texファイル保存時にコンパイルされる
  * **LaTeX-Workshopが必要**

## textlint
### ターミナルで実行
```
make lint
```

### VScode上でlintを表示させる場合
* VScodeにRemote Developmentのインストールが必要
1. コンテナを起動する
```
make bash
```
2. リモートエクスプローラにlatex-containerが表示されるのでAttach to Container

1. 編集後にコンテナを終了させる
     * コンテナ内の変更はこのときにローカルにコピーされる
```
exit
```
![latex-3](https://user-images.githubusercontent.com/71243805/175042384-17a4563b-654e-4d83-a79c-0070f718913a.gif)


### 研のlintルール
   * 場所：media/semi-rule.yml

## 画像の貼り方
* 対応しているファイル形式
  * eps
  * pdf
  * png
    * epsへの変換が必要
  * svg
    * pdfへの変換が必要
### png
* 拡張子に.pngを使わない
  * .epsで指定
  * コンテナ内で自動的にpngからepsを生成
* 例：ローカルにfig/hoge.pngがある場合
  * hoge.epsはなくても可
```
\includegraphics[]{fig/hoge.eps}
```

### svg
* 拡張子は指定しない
  * コンテナ内で自動的にsvgからpdfを生成
* 例：ローカルにfig/huga.svgがある場合
```
\includegraphics[]{fig/huga}
```

# コマンド一覧

## LaTexのコンパイル
* コンパイルされるのはworkspace内のtexファイル
```
make run
```

## サンプルのコンパイル
```
make sample
```

## TextLint
```
make lint
```

## dockerのリソースを開放
* トラブルが起きたときはとりあえず実行
```
make clean
```

## コンテナのパッケージ更新
* make buildではパッケージは更新されない
  * 過去のキャッシュが使われる
```
make rebuild
```

## Dockerのインストール
* Dockerをインストールし，sudo権限なしで動作させる設定を行う
```
make install-docker
```
