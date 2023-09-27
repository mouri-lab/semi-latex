
- [概要](#概要)
  - [動作環境](#動作環境)
- [使い方](#使い方)
  - [INSTALL](#install)
  - [LaTeXのビルド](#latexのビルド)
- [テンプレート](#テンプレート)
  - [全体ゼミ](#全体ゼミ)
  - [B3向け](#b3向け)
  - [B4向け](#b4向け)
  - [院生向け](#院生向け)
  - [学会](#学会)
- [textlint](#textlint)
  - [ターミナルから実行](#ターミナルから実行)
    - [研のlintルール](#研のlintルール)
- [画像の貼り方](#画像の貼り方)
  - [対応しているファイル形式](#対応しているファイル形式)
  - [自動変換の注意](#自動変換の注意)
    - [正しいフォルダ階層の例](#正しいフォルダ階層の例)
    - [NG例](#ng例)
  - [png](#png)
  - [svg](#svg)
- [ディレクトリ](#ディレクトリ)
- [コマンド一覧](#コマンド一覧)
  - [LaTeXのビルド](#latexのビルド-1)
  - [TextLint](#textlint-1)
  - [コンテナに入りコマンド実行](#コンテナに入りコマンド実行)
  - [コンテナを停止](#コンテナを停止)
  - [dockerのリソースを開放](#dockerのリソースを開放)
  - [コンテナのビルド](#コンテナのビルド)
  - [インストール](#インストール)
  - [Dockerのインストール](#dockerのインストール)
  - [ビルド環境のテスト](#ビルド環境のテスト)

# 概要
* LaTeX環境をローカルにインストールしたくないので作りました
* 研究室や学会で使用するLaTeXフォーマットのビルド環境です
## 動作環境
* 必要環境
  * Docker
  * make
  * Bash
* 推奨環境
  * VScode
  * 拡張機能
    * LaTeX-Workshop
      * LaTeXの補完
      * 保存時に自動ビルド
    * Remote SSH
      * WindowsからVBox上のUbuntuに接続する場合に便利です
* ホストOSについて
  * Linux
    * 推奨環境です
  * Windows
    * Virtual BoxやWSL2を使ってLinux環境を用意してください
    * VSCodeのRemote SSHを使用すると快適に作業できます
  * macOS
    * Dockerを動かすためにDocker Desktopを用意してください
    * M1 Macで動作確認済みです

# 使い方
## INSTALL
* Docker環境をインストールしてsemi-latexのDocker imageを取得
* WSLではこのコマンドでインストールできない可能性があります
* **MacユーザはDocker Desktopをインストールしてください**
```
make install
```

## LaTeXのビルド
* 作業ディレクトリ
  * このディレクトリ(semi-latex)内であれば任意のディレクトリを使用できます
    * 適当なディレクトリを作成し，その中で別途Gitでtexのバージョン管理するのがおススメです
  * make run実行時に自動的に最新のtexファイルを探索し、ビルドします

* コマンドから実行
  * ファイルを指定してLaTeXをビルド
  ```
  make f=texのpath
  ```
  例)
  ```
  make f=sample/semi-sample/semi.tex
  ```
  * semi-latexディレクトリ内で最近変更されたtexをビルド
  ```
  make
  ```
* VSCode上で実行
  * texファイル保存時にビルドします
  * **LaTeX-Workshopの拡張機能が必要**

# テンプレート
texファイルのdocumentclassで使用するテンプレートを選択できます

## 全体ゼミ
[サンプルコード](sample/semi-sample/semi.tex)
```
\documentclass[submit,techreq,noauthor,dvipdfmx]{eco}
```

## B3向け
* B3輪講
  ```
  \documentclass[submit,techreq,noauthor,dvipdfmx]{b3-eco}
  ```

## B4向け
* B4中間発表
  ```
  \documentclass[submit,techreq,noauthor,dvipdfmx]{mid-eco}
  ```
* 卒論
  * [サンプルコード](sample/graduation-thesis/main.tex)
  * 他のサンプルと違い，複数のtexファイルに分かれています

## 院生向け
* テーマ発表 & 中間発表
  * [サンプルコード](sample/master-theme-midterm/main.tex)
* 修論
  * [サンプルコード](sample/master-thesis/main.tex)
  * 卒論と同様に複数のtexファイルに分かれています

## 学会
* 全国大会
  * [サンプルコード](sample/ipsj-report/ipsj_report.tex)



# textlint
texファイルの表記ゆれや誤植を機械的に検出できます
## ターミナルから実行
* VSCode上のターミナルを使うとファイルパスのCtrl+クリックで該当箇所にジャンプできます
* このリポジトリのmakefileと同じディレクトリ階層で実行してください
```
make lint
```
* 自動修正
```
make lint-fix
```

### 研のlintルール
   * 場所：media/semi-rule.yml

# 画像の貼り方
## 対応しているファイル形式
  * eps
  * pdf
  * png
  * svg
    * pdfへ自動変換
## 自動変換の注意
  * 画像用のディレクトリを作成し，すべての画像を同じディレクトリに入れることが必要です
    * ディレクトリ名は任意
  * 作成したディレクトリ内でネストしない
### 正しいフォルダ階層の例
    ```
    sample.tex
    fig/
    |--hoge.png
    |--huga.svg
    ```
### NG例
* ディレクトリがネスト
    * fig/内にfig/が存在
    ```
    sample.tex
    fig/
    |--fig/
        |--hoge.png
        |--huga.svg
    ```
* ディレクトリに保存されていない
    ```
    sample.tex
    hoge.png
    huga.svg
    ```
## png
* 例：ローカルにfig/hoge.pngがある場合
```
\includegraphics[]{fig/hoge.png}
```

## svg
* 拡張子は指定しない
  * コンテナ内で自動的にsvgからpdfを生成
  * pdbはベクタ形式で生成
    * ベクタ形式なのでズームしても画像が荒くなりません
* 例：ローカルにfig/huga.svgがある場合
```
\includegraphics[]{fig/huga}
```

# ディレクトリ
* .github
  * GitHub Actionsの設定
* .vscode
  * VSCodeで保存時にビルドするための設定
* internal
  * 触る必要のないファイル
  * media
    * 研究室独自のlintルール
  * scripts
    * 主にコンテナ内で実行されるスクリプト
  * style
    * 全体ゼミなどのスタイルファイル
* sample
  * サンプル


# コマンド一覧

## LaTeXのビルド
ビルドされるのはsemi-latex/内で最も最近更新されたtexファイルです

makeとmake runは同じ処理
```
make
```
または
```
make run
```

## TextLint
```
make lint
```

## コンテナに入りコマンド実行
主にデバッグ用なので普段使う必要はないはず
* root権限なし
    ```
    make bash
    ```
* root権限あり
    ```
    make root
    ```

## コンテナを停止
* 1度ビルドすると再起動するまでコンテナは起動したままなので停止したい人向け
  * コンテナを毎回起動するとコンパルに時間がかかるため起動したままにしています
```
make docker-stop
```

## dockerのリソースを開放
* トラブルが起きたときはとりあえず実行すると，直る場合があります
```
make docker-clean
```

## コンテナのビルド
* キャッシュを有効にしてDocker Imageをビルド
  * キャッシュを利用するので2回目以降のビルドが高速です
  * キャッシュが原因で失敗する場合があります
  ```
  make docker-build
  ```
* コンテナをキャッシュ無しでビルド
  * キャッシュを利用しないので信頼性は高いですがビルドに時間がかかります
  ```
  make docker-rebuild
  ```

## インストール
* Dockerがインストールされていない場合はインストールする
  * Linux限定
```
make install
```

## Dockerのインストール
* Dockerをインストールし，sudo権限なしで動作させる設定を行う
  * make installから呼ばれます
```
make install-docker
```

## ビルド環境のテスト
* サンプルがビルドできることを確認
```
make test
```