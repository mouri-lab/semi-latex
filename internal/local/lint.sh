# !/bin/bash

# TEX_FILE_PATH: texファイルのパス = $1
# 	nullが指定されるとsemi-texから探索
# 	TEST_MODEに引数を渡すために使用
# 	絶対パスと相対パスのどちらでもOK

# TEST_MODE: bool = $2

readonly DIR_PATH=$(readlink -f $(dirname ${0}))

source ${DIR_PATH}/config.sh

if [[ -z $1 ]] || [[ $1 == "null" ]]; then
	readonly TEX_FILE_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh)
else
	if [[ ! -f $1 ]]; then
		echo "ファイルパスが不正: $1"
		exit 1
	fi
	readonly TEX_FILE_PATH=$1
fi

[[ ! -z $(echo ${TEX_FILE_PATH} | grep "[ERROR]") ]] && echo ${TEX_FILE_PATH} && exit 1

# if [[ -z $2 ]]; then
# 	readonly USE_FORMAT=true
# else
# 	readonly USE_FORMAT=$2
# fi

# TEST_MODE: ビルドした成果物をローカルに保存しない
if [[ -z $2 ]]; then
	readonly SHOULD_FIX=false
elif [[ $2 == true ]]; then
	readonly SHOULD_FIX=true
fi

readonly TEX_DIR_PATH=$(dirname ${TEX_FILE_PATH})
readonly TEX_FILE_NAME=$(basename ${TEX_FILE_PATH})
set -u

function lint {
	echo "$(tput setaf 2)TEX PATH:$(tput sgr0) ${TEX_FILE_PATH}"
	docker container exec -it ${CONTAINER_NAME} /bin/bash -c \
        "textlint ${DOCKER_HOME_DIR}${TEX_FILE_PATH} \
		| sed -e 's^\([0-9]\)\+:\([0-9]\)\+^\n${TEX_FILE_PATH}:&\n\t^g' \
		| sed 's/errors/$(tput setaf 1)&$(tput sgr0)/g' \
		| sed 's/error/$(tput setaf 1)&$(tput sgr0)/g' \
		| sed 's/"✓"/$(tput setaf 2)&$(tput sgr0)/g' \
		| sed 's/"✖"/$(tput setaf 1)&$(tput sgr0)/g' \
		"
}

function preExec {
	if [[ $(docker ps -a | grep -c ${CONTAINER_NAME}) -eq 0 ]]; then
		docker container run\
			-it\
			--rm\
			-d\
			--name ${CONTAINER_NAME}\
			${CONTAINER_NAME}:${ARCH}
	fi
	docker container exec ${CONTAINER_NAME} /bin/bash -c "mkdir -p ${DOCKER_HOME_DIR}${TEX_DIR_PATH}"

	docker container cp ${TEX_FILE_PATH} ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_DIR_PATH}/
	docker container cp internal/container/scripts/lint-formatter.sh ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_DIR_PATH}/
}

function postExec {
    docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "rm -rf ${DOCKER_HOME_DIR}/home"
}

function containerAttach {
	docker container exec -it ${CONTAINER_NAME} bash
}

function main {
	preExec
	lint
	postExec
}

main