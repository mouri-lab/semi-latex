# コンテナ名
NAME := latex-container

# DockerHubのリポジトリ名
# make get-imageの取得先
DOCKER_REPOSITORY := taka0628/semi-latex

SCRIPTS_DIR := internal/local

ARCH := $$(uname -m)

# ビルドするtexファイルのディレクトリ
# fはTEX_FILE_PATHのエイリアス
f :=
ifneq (${new},)
	f := ${new}
endif

TEX_FILE_PATH := ${f}
ifneq (${TEX_FILE_PATH},)
	${TEX_FILE_PATH} := null
endif

SHELL := /bin/bash

.PHONY: run
.PHONY: lint
.PHONY: bash

# make実行時に実行されるmakeコマンドの設定
.DEFAULT_GOAL := run

# LaTeXのビルド
run:
	ARCH=${ARCH} bash ${SCRIPTS_DIR}/texBuild.sh ${TEX_FILE_PATH}

# TextLint
lint:
	ARCH=${ARCH} bash ${SCRIPTS_DIR}/lint.sh ${TEX_FILE_PATH}

lint-fix:
	ARCH=${ARCH} FIX=1 bash ${SCRIPTS_DIR}/lint.sh ${TEX_FILE_PATH}


# 差分を色付けして出力
old :=
new :=
diff:
	old=${old} new=${new} bash ${SCRIPTS_DIR}/diff.sh

# sampleをビルド
run-sample:
	make run f=sample/semi-sample/semi.tex -s

# コンテナのビルド
docker-build:
	make docker-stop -s
	docker buildx build --platform linux/amd64 -t ${NAME}:x86_64 .
	make _postBuild -s

docker-buildforArm:
	make docker-stop -s
	docker buildx build --platform linux/arm64/v8 -t ${NAME}:arm64 -f Dockerfile.arm64 .
	make _postBuild -s


# キャッシュを使わずにビルド
docker-rebuild:
	make docker-stop -s
	docker buildx build --platform linux/amd64 -t ${NAME}:x86_64 \
	--pull \
	--force-rm=true \
	--no-cache=true .
	make _postBuild -s

docker-rebuildforArm:
	make docker-stop -s
	docker buildx build --platform linux/arm64/v8 -t ${NAME}:arm64 \
	-f Dockerfile.arm64 \
	--pull \
	--force-rm=true \
	--no-cache=true .
	make _postBuild -s

# dockerのリソースを開放
docker-clean:
	docker system prune -f

# dockerコンテナを停止
docker-stop:
	@if [[ $$(docker container ls -a | grep -c "${NAME}") -ne 0 ]]; then\
		docker container kill ${NAME};\
		echo "コンテナを停止";\
		sync;\
	fi
	@docker container ls -a

# コンテナを開きっぱなしにする
# リモートアクセス用
bash:
	-docker container exec -it ${NAME} bash

# root権限で起動中のコンテナに接続
# aptパッケージのインストールをテストする際に使用
root:
	make _preExec -s
	-docker container exec -it --user root ${NAME} bash
	make _postExec -s


# 不要になったビルドイメージを削除
_postBuild:
	@if [[ -n $$(docker images -f 'dangling=true' -q) ]]; then\
		docker image rm $$(docker images -f 'dangling=true' -q);\
	fi
	docker system df



# semi-latex環境の構築
install:
	@if [[ -n $$(docker --version 2>/dev/null) ]] || [[ $$(uname) == "Linux" ]]; then\
		make install-docker -s;\
	fi


# UbuntuにDockerをインストールし，sudoなしでDockerコマンドを実行するよう設定
install-docker:
	@if [[ -n $$(docker --version 2>/dev/null) ]]; then\
		echo "Docker is already installed";\
		docker --version;\
		exit 1;\
	fi
	sudo apt update
	sudo apt install -y docker.io docker-buildx
	[[ $$(getent group docker | cut -f 4 --delim=":") != $$(whoami) ]] && sudo gpasswd -a $$(whoami) docker
	sudo chgrp docker /var/run/docker.sock
	sudo systemctl restart docker
	@echo "環境構築を完了するために再起動してください"

install-textlint:
	sudo apt install nodejs npm
	sudo npm install n -g
	sudo n lts
	npm install

push-image:
	docker tag ${NAME}:${ARCH} ${DOCKER_REPOSITORY}:${ARCH}
	docker push ${DOCKER_REPOSITORY}:${ARCH}
	docker image rm ${DOCKER_REPOSITORY}:${ARCH}

get-image:
	docker pull ${DOCKER_REPOSITORY}:${ARCH}
	docker tag ${DOCKER_REPOSITORY}:${ARCH} ${NAME}:${ARCH}
	docker image rm ${DOCKER_REPOSITORY}:${ARCH}


# サンプルのビルドテスト
test:
	ARCH=${ARCH} bash ${SCRIPTS_DIR}/test.sh

sandbox:
	docker exec -it  --user root ${NAME} /bin/bash -c -x "echo "hoge hoge ""
