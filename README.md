# ゼミ用LaTeX環境
* LaTeX環境をローカルにインストールしたくないので作りました

## 動作環境
* 以下が動作する環境
  * Docker
  * make
* LaTeX-WorkshopがインストールされたVScode

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
* コマンド
```
make lint
```

* VScode上でlintを表示させる場合
  * VScodeにRemote Developmentをインストール
  * コンテナを起動する
	```
	make remote
	```
  * リモートエクスプローラにlatex-containerが表示されるのでAttach to Container
 * 研のlintルール
   * 場所：media/semi-rule.yml

## 画像の貼り方
* 対応しているファイル形式
  * eps
  * pdf
  * png
    * epsへの変換が必要
  * svg
    * pdfへの変換が必要
### pngを使う場合
* 拡張子に.pngを使わない
  * .epsで指定
  * コンテナ内で自動的にpngからepsを生成
* 例：ローカルにfig/hoge.pngがある場合
  * hoge.epsはなくても可
```
\includegraphics[]{fig/hoge.eps}
```

### svgを使う場合
* 拡張子は指定しない
  * コンテナ内で自動的にsvgからpdfを生成
* 例：ローカルにfig/huga.svgがある場合
```
\includegraphics[]{fig/huga}
```

## コマンド一覧

### LaTexのコンパイル
```
make run
```
### TextLint
```
make lint
```

### dockerのリソースを開放
* トラブルが起きたときはとりあえず実行
```
make clean
```

### コンテナのパッケージ更新
* make buildパッケージは更新されない
  * 過去のキャッシュが使われる
```
make rebuild
```

### Dockerのインストール
* Dockerをインストールし，sudo権限なしで動作させる設定を行う
```
make install-docker
```