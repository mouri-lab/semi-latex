# コンテナ名
NAME := latex-container

DOCKER_USER_NAME := guest
DOCKER_HOME_DIR := /home/${DOCKER_USER_NAME}
CURRENT_PATH := $(shell pwd)

DOCKER_REPOSITORY := taka0628/semi-latex

# コンパイルするtexファイルのディレクトリ
# 指定したディレクトリにtexファイルは1つであることが必要
TEX_DIR := workspace
ifeq ($(shell find ${TEX_DIR} -name "*.tex" -type f 2>/dev/null),)
# 指定したディレクトリ内にtexファイルが無い場合はsampleが使用される
TEX_DIR := sample
endif


TEX_FILE := $(shell find ./${TEX_DIR} -name "*.tex" -type f | rev | cut -d '/' -f 1 | rev)
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
	@- docker container exec ${NAME} /bin/bash -c "./node_modules/.bin/textlint ${TEX_DIR}/${TEX_FILE}"
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
ifeq ($(shell docker ps -a | grep -c ${NAME}),0)
	@docker container run \
	-it \
	--rm \
	--network none \
	-d \
	--name ${NAME} \
	${NAME}:latest
else
	@-docker container exec --user root ${NAME}  bash -c "cd ${DOCKER_HOME_DIR} && rm -rf ${TEX_DIR} "
endif
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

stop:
ifneq ($(shell docker container ls -a | grep -c "${NAME}"),0)
	@docker container stop ${NAME}
	@echo "コンテナを停止"
endif
	@docker container ls -a


install:
ifeq ($(shell ls | grep -c workspace),0)
	mkdir workspace
endif
ifeq ($(shell ls workspace/ 2>/dev/null | grep -c ".tex"),0)
	cp sample/*.tex workspace/
	touch workspace/references.bib
	bash sample-clean.sh
endif
ifeq ($(shell docker --version 2>/dev/null),)
ifeq (${IS_LINUX},Linux)
	-make install-docker
endif
endif
	LATEX_CONTAINER_MAKE_PATH=$(shell pwd)




# UbuntuにDockerをインストールし，sudoなしでDockerコマンドを実行する設定を行う
install-docker:
ifneq ($(shell docker --version 2>/dev/null),)
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

push-image:
	docker tag ${NAME}:latest ${DOCKER_REPOSITORY}
	docker push ${DOCKER_REPOSITORY}
	docker image rm ${DOCKER_REPOSITORY}

get-image:
	docker pull ${DOCKER_REPOSITORY}:latest
	docker tag ${DOCKER_REPOSITORY}:latest ${NAME}
	docker image rm ${DOCKER_REPOSITORY}

# コマンドのテスト用
test:
	sed "$(shell $(expr $(grep -n "section{はじめに}" workspace/semi.tex | cut -d ":" -f 1) + 1))/171d" workspace/semi.tex

