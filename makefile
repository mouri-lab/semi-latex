# コンテナ名
NAME := latex-container

DOCKER_USER_NAME := guest
DOCKER_HOME_DIR := /home/${DOCKER_USER_NAME}
CURRENT_PATH := $(shell pwd)

# texファイルのディレクトリ
ifeq ($(shell find workspace -name "*.tex" -type f),)
TEX_DIR := sample
else
TEX_DIR := $(shell find workspace -name "*.tex" -type f | cut -d '/' -f 1)
endif


TEX_FILE := $(shell find ./${TEX_DIR} -name "*.tex" -type f | cut -d '/' -f 3)
SETTING_DIR := latex-setting
SETTING_FILES := $(shell ls ${SETTING_DIR})

IS_LINUX := $(shell uname)

.PHONY: run
.PHONY: lint
.PHONY: sample
.PHONY: build
.PHONY: bash

# LaTeXのコンパイル
run:
	make pre-exec_ --no-print-directory
	-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && make all"
	-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && make all"
	@-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && latexindent -w -s ${TEX_FILE} && rm *.bak*" # texファイルの整形
	make post-exec_ --no-print-directory

# TextLint
lint:
	@make pre-exec_ --no-print-directory
	-@docker container exec ${NAME} /bin/bash -c "./node_modules/.bin/textlint ${TEX_DIR}/${TEX_FILE}"
	@make post-exec_ --no-print-directory

# sampleをビルド
sample:
	make pre-exec_ TEX_DIR=sample --no-print-directory
	-docker container exec --user root ${NAME} /bin/bash -c "cd sample && make all"
	-docker container exec --user root ${NAME} /bin/bash -c "cd sample && make all"
	@-docker container exec --user root ${NAME} /bin/bash -c "cd sample && latexindent -w -s semi.tex && rm *.bak*"
	make post-exec_ TEX_DIR=sample --no-print-directory


# GitHub Actions上でのTextLintのテスト用
github_actions_lint_:
	make lint > lint.log


# コンテナのビルド
build:
	DOCKER_BUILDKIT=1 docker image build -t ${NAME} \
	--build-arg DOCKER_USER_=${DOCKER_USER_NAME} \
	--force-rm=true .
ifneq ($(shell docker images -f 'dangling=true' -q),)
	-docker rmi $(shell docker images -f 'dangling=true' -q)
endif


# コンテナを開きっぱなしにする
# リモートアクセス用
bash:
	make pre-exec_ --no-print-directory
	-docker container exec -it ${NAME} bash
	make post-exec_ --no-print-directory


# コンテナ実行する際の前処理
# 起動，ファイルのコピーを行う
pre-exec_:
ifneq ($(shell docker ps -a | grep ${NAME}),) #起動済みのコンテナを停止
	docker container stop ${NAME}
endif
	@docker container run \
	-it \
	--rm \
	-d \
	--name ${NAME} \
	${NAME}:latest
	@-docker container cp ${TEX_DIR} ${NAME}:${DOCKER_HOME_DIR}
	@-docker container cp ${SETTING_DIR} ${NAME}:${DOCKER_HOME_DIR}
	@-docker container exec --user root ${NAME}  bash -c "cp -a ${DOCKER_HOME_DIR}/${SETTING_DIR}/* ${DOCKER_HOME_DIR}/${TEX_DIR}"
	@-docker cp .textlintrc ${NAME}:${DOCKER_HOME_DIR}/
	@-docker cp media/semi-rule.yml ${NAME}:${DOCKER_HOME_DIR}/node_modules/prh/prh-rules/media/
ifeq (${IS_LINUX},Linux)
	@-docker cp ~/.bashrc ${NAME}:${DOCKER_HOME_DIR}/.bashrc
endif

# コンテナ終了時の後処理
# コンテナ内のファイルをローカルへコピー，コンテナの削除を行う
post-exec_:
	@-docker container exec --user root ${NAME}  bash -c "cd ${DOCKER_HOME_DIR}/${TEX_DIR} && rm ${SETTING_FILES} "
	@-docker container cp ${NAME}:${DOCKER_HOME_DIR}/${TEX_DIR} .
	@docker container stop ${NAME}

# dockerのリソースを開放
clean:
	docker system prune

# キャッシュを使わずにビルド
rebuild:
	DOCKER_BUILDKIT=1 docker image build -t ${NAME} \
	--build-arg DOCKER_USER_=${DOCKER_USER_NAME} \
	--pull \
	--force-rm=true \
	--no-cache=true .

# root権限で起動中のコンテナに接続
# aptパッケージのインストールをテストする際に使用
root:
	make pre-exec_ --no-print-directory
	-docker container exec -it --user root ${NAME} bash
	make post-exec_ --no-print-directory

install:
ifeq ($(ls | grep -c workspace),0)
	mkdir workspace
endif
ifeq ($(shell docker --version),)
	ifeq (${IS_LINUX},Linux)
		-make install-docker
	endif
endif



# UbuntuにコンテナをインストールしsudoなしでDockerコマンドを実行する設定を行う
install-docker:
ifneq ($(shell docker --version),)
	exit 1
endif
	sudo apt update
	sudo apt install -y docker.io
ifneq ($(shell getent group docker| cut -f 4 --delim=":"),$(shell whoami))
	sudo gpasswd -a $(shell whoami) docker
endif
	sudo chgrp docker /var/run/docker.sock
	sudo systemctl restart docker
	@echo "環境構築を完了するために再起動してください"


test:
ifneq ($(shell docker --version),)
	exit find
else
	echo not find
endif
