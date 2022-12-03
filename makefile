# コンテナ名
NAME := latex-container

# DockerHubのリポジトリ名
# make get-imageの取得先
DOCKER_REPOSITORY := taka0628/semi-latex

# texfileの自動整形をする
# yes -> true, no -> true以外
AUTO_FORMAT := true

DOCKER_USER_NAME := $(shell cat Dockerfile | grep "ARG DOCKER_USER_" | cut -d "=" -f 2)
DOCKER_HOME_DIR := /home/${DOCKER_USER_NAME}
CURRENT_PATH := $(shell pwd)
TS := $(shell date +%Y%m%d%H%M%S)


# コンパイルするtexファイルのディレクトリ
# 指定したディレクトリにtexファイルは1つであることが必要
TEX_FILE_PATH := $(shell bash latex-setting/file-explorer.sh)
TEX_FILE := $(shell echo ${TEX_FILE_PATH} | rev | cut -d '/' -f 1 | rev)

TEX_DIR_PATH := $(shell echo ${TEX_FILE_PATH} | sed -e "s@${TEX_FILE}@@" -e "s@$(shell pwd)/@@")
TEX_DIR := $(shell echo ${TEX_DIR_PATH} | rev | cut -d "/" -f 2 | rev)

SETTING_DIR := latex-setting
SETTING_FILES := $(shell ls ${SETTING_DIR})

IS_LINUX := $(shell uname)
SHELL := /bin/bash

.PHONY: run
.PHONY: lint
.PHONY: bash

# make実行時に実行されるmakeコマンドの設定
.DEFAULT_GOAL := run

# LaTeXのコンパイル
run:
	make _preExec -s
	-bash latex-setting/build.sh ${NAME} ${TEX_DIR} ${TEX_FILE}
# texファイルの整形
ifeq (${AUTO_FORMAT},true)
	-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && latexindent -w ${TEX_FILE} -s && rm -f *.bak*"
endif
	make _postExec -s

# TextLint
lint:
	@make _preExec -s
	@- docker container exec --user root ${NAME} /bin/bash -c "textlint ${TEX_DIR}/${TEX_FILE} > ${TEX_DIR}/lint.txt"
	- docker container exec --user root -t --env TEX_PATH="$(shell readlink -f ${TEX_DIR})" ${NAME} /bin/bash -c "cd ${TEX_DIR} && bash lint-formatter.sh ${TEX_FILE_PATH}"
	@- docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && rm -f lint.txt"
	@make _postExec -s

lint-fix:
	@make _preExec -s
	@- docker container exec --user root -t ${NAME} /bin/bash -c "textlint --fix ${TEX_DIR}/${TEX_FILE}"
	@make _postExec -s

# sampleをビルド
run-sample:
	make _preExec TEX_DIR=sample -s
	-bash latex-setting/build.sh ${NAME} ${TEX_DIR} ${TEX_FILE}
ifeq (${AUTO_FORMAT},true)
	docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && latexindent -w -s ${TEX_FILE} && rm *.bak*"
endif
	make _postExec TEX_DIR=sample -s

# コンテナのビルド
docker-build:
	make docker-stop -s
	DOCKER_BUILDKIT=1 docker image build -t ${NAME} \
	--build-arg TS=${TS} \
	--force-rm=true .
	make _postBuild -s


# キャッシュを使わずにビルド
docker-rebuild:
	make docker-stop -s
	DOCKER_BUILDKIT=1 docker image build -t ${NAME} \
	--pull \
	--force-rm=true \
	--no-cache=true .
	make _postBuild -s


# dockerのリソースを開放
docker-clean:
	docker system prune -f

# dockerコンテナを停止
docker-stop:
	@if [[ $$(docker container ls -a | grep -c "${NAME}") -eq 0 ]]; then\
		docker container stop ${NAME};\
		echo "コンテナを停止";\
		sync;\
	fi
	@docker container ls -a

# コンテナを開きっぱなしにする
# リモートアクセス用
bash:
	make _preExec -s
	-docker container exec -it ${NAME} bash
	make _postExec -s

# root権限で起動中のコンテナに接続
# aptパッケージのインストールをテストする際に使用
root:
	make _preExec -s
	-docker container exec -it --user root ${NAME} bash
	make _postExec -s

# コンテナ実行する際の前処理
# 起動，ファイルのコピーを行う
_preExec:
	@if [[ $$(docker ps -a | grep -c ${NAME}) -eq 0 ]]; then\
		docker container run \
		-it \
		--rm \
		-d \
		--name ${NAME} \
		${NAME}:latest;\
	fi
	-docker container cp ${TEX_DIR_PATH} ${NAME}:${DOCKER_HOME_DIR}/
	-docker container cp ${SETTING_DIR} ${NAME}:${DOCKER_HOME_DIR}
	-docker container exec --user root ${NAME}  /bin/bash -c "cp -a ${DOCKER_HOME_DIR}/${SETTING_DIR}/* ${DOCKER_HOME_DIR}/${TEX_DIR}"
	-@[[ ${IS_LINUX} == "Linux" ]] && docker cp ~/.bashrc ${NAME}:${DOCKER_HOME_DIR}/.bashrc

# コンテナ終了時の後処理
# コンテナ内のファイルをローカルへコピー，コンテナの削除を行う
_postExec:
	-docker container exec --user root ${NAME}  bash -c "cd ${DOCKER_HOME_DIR}/${TEX_DIR} && rm ${SETTING_FILES} "
	-docker container cp ${NAME}:${DOCKER_HOME_DIR}/${TEX_DIR} ${TEX_DIR_PATH}../
	-docker container exec --user root ${NAME}  /bin/bash -c "cd ${DOCKER_HOME_DIR} && rm -rf ${TEX_DIR} "


# 不要になったビルドイメージを削除
_postBuild:
	@if [[ -n $$(docker images -f 'dangling=true' -q) ]]; then\
		docker image rm $$(docker images -f 'dangling=true' -q);\
	fi


install:
	@if [[ -n $$(docker --version 2>/dev/null) ]] || [[ $${IS_LINUX} != "Linux" ]]; then\
		make install-docker -s;\
	fi


# UbuntuにDockerをインストールし，sudoなしでDockerコマンドを実行する設定を行う
install-docker:
	@if [[ -n $$(docker --version 2>/dev/null) ]]; then\
		echo "Docker is already installed";\
		docker --version;\
		exit 1;\
	fi
	sudo apt update
	sudo apt install -y docker.io
	[[ $$(getent group docker | cut -f 4 --delim=":") != $$(whoami) ]] && sudo gpasswd -a $$(whoami) docker
	sudo chgrp docker /var/run/docker.sock
	sudo systemctl restart docker
	@echo "環境構築を完了するために再起動してください"

push-image:
	docker tag ${NAME}:latest ${DOCKER_REPOSITORY}
	docker push ${DOCKER_REPOSITORY}
	docker image rm ${DOCKER_REPOSITORY}

get-image:
	docker pull ${DOCKER_REPOSITORY}:latest
	docker tag ${DOCKER_REPOSITORY}:latest ${NAME}:latest
	docker image rm ${DOCKER_REPOSITORY}


# コマンドのテスト用
test:
	if [[ $$(docker ps -a | grep -c ${NAME}) -eq 0 ]]; then\
		docker container run \
		-it \
		--rm \
		-d \
		--name ${NAME} \
		${NAME}:latest;\
	fi
	echo "done!"