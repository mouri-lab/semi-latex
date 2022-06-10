# ゼミ用LaTeX環境

## 動作環境
* docker&makeが動作する環境
* latex-workshopがインストールされたVScode

## INSTALL
```
sudo apt install docker.io make
#workspace内
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