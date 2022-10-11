# コンテナ名
NAME := latex-container

# DockerHubのリポジトリ名
DOCKER_REPOSITORY := taka0628/semi-latex


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

# ifeq ($(shell find ${TEX_DIR} -name "*.tex" -type f 2>/dev/null),)
# # 指定したディレクトリ内にtexファイルが無い場合はsampleが使用される
# # TEX_DIR := sample
# endif

SETTING_DIR := latex-setting
SETTING_FILES := $(shell ls ${SETTING_DIR})

IS_LINUX := $(shell uname)
SHELL := /bin/bash

.PHONY: run
.PHONY: lint
.PHONY: bash

# LaTeXのコンパイル
run:
	make _preExec -s
	-bash latex-setting/build.sh ${NAME} ${TEX_DIR} ${TEX_FILE}
# texファイルの整形
	@-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && latexindent -w -s ${TEX_FILE} && rm *.bak*"
	make _postExec -s

# TextLint
lint:
	@make _preExec -s
	@- docker container exec --user root ${NAME} /bin/bash -c "./node_modules/textlint/bin/textlint.js ${TEX_DIR}/${TEX_FILE} > ${TEX_DIR}/lint.txt"
	- docker container exec --user root -t --env TEX_PATH="$(shell readlink -f ${TEX_DIR})" ${NAME} /bin/bash -c "cd ${TEX_DIR} && bash lint-formatter.sh ${TEX_FILE_PATH}"
	@- docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && rm -f lint.txt"
	@make _postExec -s

# sampleをビルド
run-sample:
	make _preExec TEX_DIR=sample -s
	-bash latex-setting/build.sh ${NAME} ${TEX_DIR} ${TEX_FILE}
	@-docker container exec --user root ${NAME} /bin/bash -c "cd sample && latexindent -w -s semi.tex && rm *.bak*"
	make _postExec TEX_DIR=sample -s



# GitHub Actions上でのTextLintのテスト用
github_actions_lint_:
	-make lint -s > lint.log


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

docker-stop:
ifneq ($(shell docker container ls -a | grep -c "${NAME}"),0)
	@docker container stop ${NAME}
	@echo "コンテナを停止"
	sync
endif
	@docker container ls -a

# コンテナを開きっぱなしにする
# リモートアクセス用
bash:
	make _preExec
	-docker container exec -it ${NAME} bash
	make _postExec

# root権限で起動中のコンテナに接続
# aptパッケージのインストールをテストする際に使用
root:
	make _preExec -s
	-docker container exec -it --user root ${NAME} bash
	make _postExec -s

# コンテナ実行する際の前処理
# 起動，ファイルのコピーを行う
_preExec:
ifeq ($(shell docker ps -a | grep -c ${NAME}),0)
	docker container run \
	-it \
	--rm \
	--network none \
	-d \
	--name ${NAME} \
	${NAME}:latest
else
endif
	-docker container cp ${TEX_DIR_PATH} ${NAME}:${DOCKER_HOME_DIR}/
	-docker container cp ${SETTING_DIR} ${NAME}:${DOCKER_HOME_DIR}
	-docker container exec --user root ${NAME}  /bin/bash -c "cp -a ${DOCKER_HOME_DIR}/${SETTING_DIR}/* ${DOCKER_HOME_DIR}/${TEX_DIR}"
ifeq (${IS_LINUX},Linux)
	-docker cp ~/.bashrc ${NAME}:${DOCKER_HOME_DIR}/.bashrc
endif

# コンテナ終了時の後処理
# コンテナ内のファイルをローカルへコピー，コンテナの削除を行う
_postExec:
	-docker container exec --user root ${NAME}  bash -c "cd ${DOCKER_HOME_DIR}/${TEX_DIR} && rm ${SETTING_FILES} "
	-docker container cp ${NAME}:${DOCKER_HOME_DIR}/${TEX_DIR} ${TEX_DIR_PATH}../
	-docker container exec --user root ${NAME}  /bin/bash -c "cd ${DOCKER_HOME_DIR} && rm -rf ${TEX_DIR} "


# 不要になったビルドイメージを削除
_postBuild:
	if [[ -n $$(docker images -f 'dangling=true' -q) ]]; then\
		 docker image rm $$(docker images -f 'dangling=true' -q);\
	fi


install:
ifeq ($(shell docker --version 2>/dev/null),)
ifeq (${IS_LINUX},Linux)
	-make install-docker
endif
endif


# UbuntuにDockerをインストールし，sudoなしでDockerコマンドを実行する設定を行う
install-docker:
ifneq ($(shell docker --version 2>/dev/null),)
	exit 1
endif
	sudo apt update
	sudo apt install -y docker.io
	if [[ $$(getent group docker | cut -f 4 --delim=":") != $$(whoami) ]]; then\
		sudo gpasswd -a $$(whoami) docker;\
	fi
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
	@echo ${TEX_FILE_PATH}
	@echo ${TEX_FILE}
	@echo ${TEX_DIR_PATH}
	@echo ${TEX_DIR}


