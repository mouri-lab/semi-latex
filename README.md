
- [概要](#概要)
  - [動作環境](#動作環境)
- [使い方](#使い方)
  - [INSTALL](#install)
  - [コンパイル](#コンパイル)
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
  - [png](#png)
  - [svg](#svg)
- [ディレクトリ](#ディレクトリ)
- [コマンド一覧](#コマンド一覧)
  - [LaTexのコンパイル](#latexのコンパイル)
  - [サンプルのコンパイル](#サンプルのコンパイル)
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
      * 保存時に自動コンパイル
    * Remote Development
      * VScode上にTextLintのエラーを表示させる場合に使用
* ホストOS
  * Windows
    * Virtual BoxやWSL2を使ってLinux環境を用意してください
  * macOS
    * Intel, M1, M2に関わらすDocker Desktopでの実行を確認できていません
    * OverleafやCloud LaTeXなどの利用をおすすめします

# 使い方
## INSTALL
1. Docker環境をインストール
     * Docker環境を構築済みの方は1と2をスキップしてください
     * WSLではこのコマンドでインストールできない可能性があります
       * aptのdocker.ioでDockerが入らないかも
       * Docker公式ドキュメント記載の方法でインストールしてください
    ```
    make install
    ```
2. 再起動
3. Docker Imageの作成
   * どちらか好きな方を実行してください
   *  Docker Hubから構築済みイメージを取得
      * Docker Imageのビルドが不要な分高速です
       ```
       make get-image
       ```
   * Dockerのビルド
     * DockerfileからDocker Imageをビルド
     * ほぼ確実にDocker Imageを取得できます
       * make get-imageより信頼性は高いです
      ```
      make docker-build
      ```

## コンパイル
* 作業ディレクトリ
  * このディレクトリ(semi-latex)内であれば任意のディレクトリを使用できます
  * make run実行時に自動的に最新のtexファイルを探索し、コンパイルします

* コマンドから実行
  * semi-latexディレクトリ内で変更されたtexをコンパイル
  ```
  make
  ```
* VSCode上で実行
  * texファイル保存時にコンパイル
  * **LaTeX-Workshopが必要**

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
* テーマ発表
  * [サンプルコード](sample/master-theme-midterm/main.tex)

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
  * 画像用のディレクトリを作成し，すべての画像を同じディレクトリに入れることが必要
    * ディレクトリ名は任意
  * 作成したディレクトリ内でネストしない
  * 正しいフォルダ階層の例
    ```
    sample.tex
    fig/
    |--hoge.png
    |--huga.svg
    ```
  * NG例
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
  * VSCodeで保存時にコンパイルするための設定
* internal
  * 触る必要のないファイルがまとめてあります
  * media
    * 研究室独自のlintルール
  * scripts
    * 主にコンテナ内で実行されるスクリプトです
  * style
    * 全体ゼミなどのスタイルファイルです
* sample
  * texのサンプルがおいてあります


# コマンド一覧

## LaTexのコンパイル
コンパイルされるのはsemi-latex/内で最も最近更新されたtexファイルです

makeとmake runは同じ処理
```
make
```
または
```
make run
```

## サンプルのコンパイル
sample/sample.texがコンパイルされます
```
make run-sample
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
* 1度コンパイルすると再起動するまでコンテナは起動したままなので停止したい人向け
  * コンテナを毎回起動するとコンパルに時間がかかるため起動したままにしています
```
make docker-stop
```

## dockerのリソースを開放
* トラブルが起きたときはとりあえず実行
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