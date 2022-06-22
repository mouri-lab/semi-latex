
- [概要](#概要)
  - [動作環境](#動作環境)
- [使い方](#使い方)
  - [INSTALL](#install)
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
* VScodeの拡張機能
  * LaTeX-Workshop
    * LaTeXの補完
    * 保存時に自動コンパイル
  * Remote Development
    * VScode上にTextLintのエラーを表示させる

# 使い方
## INSTALL
* Dockerのインストール
  * (注)このコマンドはUbuntuのみで実行可能
    * Mac OS, Windowsは個別にDockerとmakeの実行環境を作ってください
  * インストール後に再起動が必要
```
make install-docker
```

* Dockerのビルド
  * インストールした後にDockerFileをビルドする必要があります
```
make build
```

## コンパイル
* コマンドから実行
```
make run
```
* VSCode上で実行
  * texファイル保存時にコンパイルされる

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
```
make run
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
* make buildパッケージは更新されない
  * 過去のキャッシュが使われる
```
make rebuild
```

## Dockerのインストール
* Dockerをインストールし，sudo権限なしで動作させる設定を行う
```
make install-docker
```
