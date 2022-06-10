# ゼミ用LaTeX環境
* LaTeX環境をローカルにインストールしたくないので作りました

## 動作環境
* 以下が動作する環境
  * Docker
  * make
* LaTeX-WorkshopがインストールされたVScode

## INSTALL
* Dockerのインストール
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
* コマンド
```
make run
```
* VSCode上
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