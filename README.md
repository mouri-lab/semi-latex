
- [概要](#概要)
  - [動作環境](#動作環境)
- [使い方](#使い方)
  - [INSTALL](#install)
  - [作業場所](#作業場所)
  - [コンパイル](#コンパイル)
  - [textlint](#textlint)
    - [ターミナルで実行](#ターミナルで実行)
    - [VScode上でlint結果を表示](#vscode上でlint結果を表示)
    - [研のlintルール](#研のlintルール)
  - [画像の貼り方](#画像の貼り方)
    - [png](#png)
    - [svg](#svg)
- [コマンド一覧](#コマンド一覧)
  - [LaTexのコンパイル](#latexのコンパイル)
  - [サンプルのコンパイル](#サンプルのコンパイル)
  - [TextLint](#textlint-1)
  - [コンテナに入りコマンド実行](#コンテナに入りコマンド実行)
  - [コンテナを停止](#コンテナを停止)
  - [dockerのリソースを開放](#dockerのリソースを開放)
  - [コンテナのパッケージ更新](#コンテナのパッケージ更新)
  - [インストール](#インストール)
  - [Dockerのインストール](#dockerのインストール)

# 概要
* LaTeX環境をローカルにインストールしたくないので作りました
## 動作環境
* 必要環境
  * Docker
  * make
* 推奨環境
  * VScode
  * VScodeの拡張機能
    * LaTeX-Workshop
      * LaTeXの補完
      * 保存時に自動コンパイル
    * Remote Development
      * VScode上にTextLintのエラーを表示させる

# 使い方
## INSTALL
1. 環境をインストール
   * **Ubuntuのみ**Docker環境を自動インストール
    * Mac OS, Windowsは個別にDockerとmakeの実行環境を作ってください
    ```
    make install
    ```
2. 再起動
3. Dockerのビルド
     * 所要時間：5~10分（ネットワークの速度依存）
     * 5GBのイメージを作るので時間がかかる
    ```
    make build
    ```

## 作業場所
* **workspace**
  * workspace内のファイルはGitの追跡対象外
  * make install時にフォルダとファイルが作成される

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

### VScode上でlint結果を表示
* VScodeにRemote Developmentのインストールが必要
1. コンテナに接続
    ```
    make bash
    ```
2. リモートエクスプローラにlatex-containerが表示されるのでAttach to Container
   * 初回実行時にはリモートコンテナのVScodeにvscode-textlintのインストールが必要

3. 編集後にコンテナを終了させる
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
  * 他のディレクトリをコンパイルしたいときはmakefileを書き換えて
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

## コンテナに入りコマンド実行
* root権限なし
    ```
    make bash
    ```
* root権限あり
    ```
    make root
    ```

## コンテナを停止
* 1度コンパイルすると再起動するまでコンテナは起動したままになる
  * コンテナを毎回起動するとコンパルに時間がかかるため
* アイドル状態のコンテナはリソースをほとんど消費しないので放置しても問題ない
  * CPU使用率は0~0.1%
  * コンテナはオフラインなのでネットワーク帯域を消費しない
  * メモリは数MB消費
* それでも停止したい人向け
```
make stop
```

## dockerのリソースを開放
* トラブルが起きたときはとりあえず実行
```
make clean
```

## コンテナのパッケージ更新
* make buildではパッケージが更新されない
  * キャッシュが使われるため
```
make rebuild
```

## インストール
* workspaceディレクトリの作成とtexファイル, bibtexファイルを作成する
* Dockerがインストールされていない場合はインストールする
  * Linux限定
```
make install
```

## Dockerのインストール
* Dockerをインストールし，sudo権限なしで動作させる設定を行う
  * 基本的にはmake installでOK
```
make install-docker
```
