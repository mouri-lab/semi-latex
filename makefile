NAME := latex-container
TS := `date +%Y%m%d%H%M%S`
DOCKER_USER_NAME := guest
DOCKER_HOME_DIR := /home/${DOCKER_USER_NAME}
CURRENT_PATH := $(shell pwd)
TEX_DIR := semi-eco-reiwa
TEXFILE := $(shell find . -name "*.tex" -type f | cut -d '/' -f 3)
IS_LINUX := $(shell uname)

.PHONY: run
.PHONY: lint
.PHONY: build
.PHONY: remote

# コンテナ実行
run:
ifneq ($(shell docker ps -a | grep ${NAME}),) #起動済みのコンテナを停止
	docker container stop ${NAME}
endif
	make pre-exec_ --no-print-directory
	-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && make all"
	-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && make all"
	@-docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && latexindent -w -s ${TEXFILE} && rm *.bak*" # texファイルの整形
	make post-exec_ --no-print-directory

lint:
ifneq ($(shell docker ps -a | grep ${NAME}),) #起動済みのコンテナを停止
	docker container stop ${NAME}
endif
	make pre-exec_ --no-print-directory
	-docker container exec ${NAME} /bin/bash -c "./node_modules/.bin/textlint ${TEX_DIR}/${TEXFILE}"
	make post-exec_ --no-print-directory

build:
	DOCKER_BUILDKIT=1 docker image build -t ${NAME} \
	--build-arg DOCKER_USER_=${DOCKER_USER_NAME} \
	--force-rm=true .
ifneq ($(shell docker images -f 'dangling=true' -q),)
	-docker rmi $(shell docker images -f 'dangling=true' -q)
endif

remote:
	make pre-exec_ --no-print-directory
	-docker cp remote/.devcontainer ${NAME}:${DOCKER_HOME_DIR}/
	-docker cp remote/settings.json ${NAME}:${DOCKER_HOME_DIR}/
	-docker container exec -it ${NAME} bash
	make post-exec_ --no-print-directory

bash:
	make pre-exec_ --no-print-directory
	-docker container exec -it ${NAME} bash
	make post-exec_ --no-print-directory

pre-exec_:
	@docker container run \
	-it \
	--rm \
	-d \
	--name ${NAME} \
	${NAME}:latest
	@-docker container cp ${TEX_DIR} ${NAME}:${DOCKER_HOME_DIR}
	@-docker cp .textlintrc ${NAME}:${DOCKER_HOME_DIR}/
	@-docker cp media/semi-rule.yml ${NAME}:${DOCKER_HOME_DIR}/node_modules/prh/prh-rules/media/
ifeq (${IS_LINUX},Linux)
	@-docker cp ~/.bashrc ${NAME}:${DOCKER_HOME_DIR}/.bashrc
endif

post-exec_:
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
connect:
	docker exec -u root -it ${NAME} /bin/bash

install-docker:
ifneq (${IS_LINUX},Linux)
	echo "このコマンドはLinuxでのみ使用できます"
	echo "その他のOSを使っている場合は別途Docker環境を用意してください"
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

PNG := $(shell find semi-eco-reiwa/fig -name "*.png" -type f)
png2eps: ${PNG:%.png=%.eps}

%.eps: %.png
	convert $^ eps2:$@

test:
	echo $(shell find . -name "*.tex" -type f -printf '%f\n')
	echo $(shell find . -name "*.tex" -type f | cut -d '/' -f 3)
