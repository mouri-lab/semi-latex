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

STYLE_DIR := internal/style
SCRIPTS_DIR := internal/scripts
INTERAL_FILES := $(shell ls ${STYLE_DIR})
INTERAL_FILES += $(shell ls ${SCRIPTS_DIR})

# コンパイルするtexファイルのディレクトリ
# 指定したディレクトリにtexファイルは1つであることが必要
f :=
TEX_FILE_PATH := ${f}
ifeq (${TEX_FILE_PATH},)
ifeq ($(shell uname),Linux)
TEX_FILE_PATH := $$(bash ${SCRIPTS_DIR}/file-explorer.sh)
TEX_FILE := $(shell echo ${TEX_FILE_PATH} | rev | cut -d '/' -f 1 | rev)
TEX_DIR_PATH := $(shell echo ${TEX_FILE_PATH} | sed -e "s@${TEX_FILE}@@" -e "s@$(shell pwd)/@@")
else
TEX_FILE_PATH := $$(bash ${SCRIPTS_DIR}/file-explorer-for-mac.sh)
TEX_FILE := $(shell echo ${TEX_FILE_PATH} | rev | cut -d '/' -f 1 | rev)
TEX_DIR_PATH := $(shell echo ${TEX_FILE_PATH} | sed -e "s@${TEX_FILE}@@")
endif
else
TEX_FILE := $(shell echo ${TEX_FILE_PATH} | rev | cut -d '/' -f 1 | rev)
TEX_DIR_PATH := $(shell echo ${TEX_FILE_PATH} | sed -e "s@${TEX_FILE}@@" -e "s@$(shell pwd)/@@")
endif

TEX_DIR := $(shell echo ${TEX_DIR_PATH} | rev | cut -d "/" -f 2 | rev)

SHELL := /bin/bash

.PHONY: run
.PHONY: lint
.PHONY: bash

# make実行時に実行されるmakeコマンドの設定
.DEFAULT_GOAL := run

# LaTeXのコンパイル
run:
	make _preExec -s
	-bash ${SCRIPTS_DIR}/build.sh ${NAME} ${TEX_DIR} ${TEX_FILE}
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
	make run f=sample/semi-sample/semi.tex -s

# コンテナのビルド
docker-build:
	make docker-stop -s
	DOCKER_BUILDKIT=1 docker image build -t ${NAME} .
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
	@if [[ $$(docker container ls -a | grep -c "${NAME}") -ne 0 ]]; then\
		docker container kill ${NAME};\
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
	-docker container cp ${STYLE_DIR} ${NAME}:${DOCKER_HOME_DIR}
	-docker container cp ${SCRIPTS_DIR} ${NAME}:${DOCKER_HOME_DIR}
	-docker container cp ${TEX_DIR_PATH} ${NAME}:${DOCKER_HOME_DIR}
	-docker container exec --user root ${NAME}  /bin/bash -c "cp -n ${DOCKER_HOME_DIR}/style/* ${DOCKER_HOME_DIR}/${TEX_DIR}"
	-docker container exec --user root ${NAME}  /bin/bash -c "cp -n ${DOCKER_HOME_DIR}/scripts/* ${DOCKER_HOME_DIR}/${TEX_DIR}"

# コンテナ終了時の後処理
# コンテナ内のファイルをローカルへコピー，コンテナの削除を行う
_postExec:
	-docker container exec --user root ${NAME}  bash -c "cd ${DOCKER_HOME_DIR}/${TEX_DIR} && rm ${INTERAL_FILES} "
	-docker container exec --user root ${NAME} /bin/bash -c "rm -f \
		$$(docker container exec --user root ${NAME} /bin/bash -c  "find . -name "*.xbb" -type f" | sed -z 's/\n/ /g' )"
	-docker container cp ${NAME}:${DOCKER_HOME_DIR}/${TEX_DIR} ${TEX_DIR_PATH}../
	-docker container exec --user root ${NAME}  /bin/bash -c "cd ${DOCKER_HOME_DIR} && rm -rf ${TEX_DIR} "


# 不要になったビルドイメージを削除
_postBuild:
	@if [[ -n $$(docker images -f 'dangling=true' -q) ]]; then\
		docker image rm $$(docker images -f 'dangling=true' -q);\
	fi


install:
	@if [[ -n $$(docker --version 2>/dev/null) ]] || [[ $$(uname) != "Linux" ]]; then\
		exit 1;\
	fi
# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Add the repository to Apt sources:
	echo \
	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin



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


# サンプルのビルドテスト
test:
# セミ資料
	@rm -f sample/semi-sample/*.pdf
	@make run f=sample/semi-sample/semi.tex
	@make docker-stop
	@if [[ $$(cat sample/semi-sample/semi.log | grep -c "No pages of output") -ne 0 ]] || [[ -z $$(ls sample/semi-sample/*.pdf) ]]; then\
		cat sample/semi-sample/semi.log;\
		echo "semi-sample FAILED";\
		exit 1;\
	fi
# 全国大会
	@rm -f sample/ipsj-report/*.pdf
	@make run f=sample/ipsj-report/ipsj_report.tex
	@make docker-stop
	@if [[ $$(cat sample/ipsj-report/ipsj_report.log | grep -c "No pages of output") -ne 0 ]] || [[ -z $$(ls sample/ipsj-report/*.pdf) ]]; then\
		cat sample/ipsj-report/ipsj_report.log;\
		echo "ipsj-report FAILED";\
		exit 1;\
	fi
# マスター中間発表
	@rm -f sample/master-theme-midterm/*.pdf
	@make run f=sample/master-theme-midterm/main.tex
	@make docker-stop
	@if [[ $$(cat sample/master-theme-midterm/main.log | grep -c "No pages of output") -ne 0 ]] || [[ -z $$(ls sample/master-theme-midterm/*.pdf) ]]; then\
		cat sample/master-theme-midterm/main.log;\
		echo "master-theme-midterm FAILED";\
		exit 1;\
	fi
# 卒論
	@rm -f sample/graduation-thesis/*.pdf
	@make run f=sample/graduation-thesis/main.tex
	@make docker-stop
	@if [[ $$(cat sample/graduation-thesis/main.log | grep -c "No pages of output") -ne 0 ]] || [[ -z $$(ls sample/graduation-thesis/*.pdf) ]] ; then\
		cat sample/graduation-thesis/main.log;\
		echo "graduation thesis FAILED";\
		exit 1;\
	fi
# 修論
	@rm -f sample/master-thesis/*.pdf
	@make run f=sample/master-thesis/main.tex
	@make docker-stop
	@if [[ $$(cat sample/master-thesis/main.log | grep -c "No pages of output") -ne 0 ]] || [[ -z $$(ls sample/master-thesis/*.pdf) ]] ; then\
		cat sample/master-thesis/main.log;\
		echo "master thesis FAILED";\
		exit 1;\
	fi
	@echo "SUCCESS!"

sandbox:
	echo ${f}
	echo ${TEX_FILE_PATH}
