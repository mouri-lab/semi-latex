
- [概要](#概要)
  - [動作環境](#動作環境)
- [使い方](#使い方)
  - [INSTALL](#install)
  - [コンパイル](#コンパイル)
    - [B3用のテンプレート](#b3用のテンプレート)
  - [textlint](#textlint)
    - [ターミナルで実行](#ターミナルで実行)
    - [VSCode上でlint結果を表示](#vscode上でlint結果を表示)
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
  * Linux
  * Docker
  * make
  * Bash
* 推奨環境
  * VScode
  * VScodeの拡張機能
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
    ```
    make install
    ```
2. 再起動
3. Docker Imageの作成
   *  Docker Hubからイメージを取得
      * 推奨
       ```
       make get-image
       ```
   * Dockerのビルド
     * Docker Hubから取得出来なかった場合などに使用
     * 時間がかかるので非推奨
       * 約5分
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

### B3用のテンプレート
texファイルのdocumentclassでecoではなくb3-ecoを指定してください
```
\documentclass[submit,techreq,noauthor,dvipdfmx]{b3-eco}
```
ゼミ用テンプレートに戻すにはecoを指定
```
\documentclass[submit,techreq,noauthor,dvipdfmx]{eco}
```

## textlint
texファイルの表記ゆれや誤植を表示できます
### ターミナルで実行
* VSCode上のターミナルを使うとファイルパスのCtrl+クリックで該当箇所にジャンプできます
```
make lint
```
* 自動修正
```
make lint-fix
```


### VSCode上でlint結果を表示
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
  * svg
    * pdfへ自動変換
* 自動変換の注意
  * 画像用のディレクトリを作成し，すべての画像を同じディレクトリに入れる
    * ディレクトリ名は任意
  * 作成したディレクトリ内でネストしない
  * フォルダ階層の例
    ```
    sample.tex
    fig/
    |--hoge.png
    |--huga.svg
    ```
  * NG
    * ディレクトリがネスト
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
### png
* png形式に対応しました
* 例：ローカルにfig/hoge.pngがある場合
```
\includegraphics[]{fig/hoge.png}
```

### svg
* 拡張子は指定しない
  * コンテナ内で自動的にsvgからpdfを生成
  * pdbはベクタ形式で生成
    * ベクタ形式なのでズームしても画像が荒くなりません
* 例：ローカルにfig/huga.svgがある場合
```
\includegraphics[]{fig/huga}
```

# コマンド一覧

## LaTexのコンパイル
* コンパイルされるのはsami-latex/内で最も最近更新されたtexファイルです
```
make
```
または
```
make run
```

## サンプルのコンパイル
```
make run-sample
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
make docker-stop
```

## dockerのリソースを開放
* トラブルが起きたときはとりあえず実行
```
make docker-clean
```

## コンテナのパッケージ更新
* aptパッケージの更新
  ```
  make docker-build
  ```
* コンテナの再構築
  * 5分ほどかかります
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
  * 基本的にはmake installでOK
```
make install-docker
```
