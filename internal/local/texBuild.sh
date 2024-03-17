# !/bin/bash

# TEX_FILE_PATH: texファイルのパス = $1
# 	nullが指定されるとsemi-texから探索
# 	TEST_MODEに引数を渡すために使用
# TEST_MODE: bool = $2

readonly CONTAINER_NAME=latex-container
readonly STYLE_DIR=internal/container/style
readonly SCRIPTS_DIR=internal/local
readonly DOCKER_HOME_DIR=/home/guest
readonly ARCH=$(uname -m)

if [[ -z $1 ]] || [[ $1 == "null" ]]; then
	readonly TEX_FILE_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh)
else
	if [[ ! -f $1 ]]; then
		echo "ファイルパスが不正: $1"
		exit 1
	fi
	readonly TEX_FILE_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh $1)
fi
[[ ! -z $(echo ${TEX_FILE_PATH} | grep "[ERROR]") ]] && echo ${TEX_FILE_PATH} && exit 1

# if [[ -z $2 ]]; then
# 	readonly USE_FORMAT=true
# else
# 	readonly USE_FORMAT=$2
# fi

# TEST_MODE: ビルドした成果物をローカルに保存しない
if [[ -z $2 ]]; then
	readonly TEST_MODE=false
else
	readonly TEST_MODE=$2
fi

readonly DIR_PATH=$(readlink -f $(dirname ${0}))
readonly TEX_DIR_PATH=$(dirname ${TEX_FILE_PATH})
readonly TEX_FILE_NAME=$(basename ${TEX_FILE_PATH})
set -ux

function texBuild {
	echo "$(tput setaf 2)TEX PATH: ${TEX_FILE_PATH} $(tput sgr0)"
	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cd ${DOCKER_HOME_DIR}${TEX_DIR_PATH} && make all MY-MAIN=$(echo ${TEX_FILE_NAME} | sed s/.tex//)"
}

function fileFormat {
	docker container exec ${CONTAINER_NAME} /bin/bash -c "cd ${DOCKER_HOME_DIR}${TEX_DIR_PATH} && latexindent -w ${TEX_FILE_NAME} -s && rm -f *.bak*"
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

	docker container cp ${TEX_DIR_PATH} ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_DIR_PATH}/../

	docker container exec --user root ${CONTAINER_NAME}  /bin/bash -c \
		"cp -n ${DOCKER_HOME_DIR}/internal/style/* ${DOCKER_HOME_DIR}${TEX_DIR_PATH} \
		&& cp -n ${DOCKER_HOME_DIR}/internal/scripts/* ${DOCKER_HOME_DIR}${TEX_DIR_PATH}"
}

function postExec {
	# texの成果物のみを残す
	docker container exec ${CONTAINER_NAME} /bin/bash -c \
		"cd ${DOCKER_HOME_DIR}${TEX_DIR_PATH} \
		&& find . -maxdepth 1 -type f -not \( -name '*.tex' -o -name '*.aux' -o -name '*.div' -o -name '*.log' \) -exec rm -f {} + "

	#ビルド中にローカルのtexファイルが更新されている場合，ローカルのtexファイルを上書きしない
	if [[ ${TEST_MODE} != true ]]; then
		if [[ $(date -r ${TEX_FILE_PATH} +%s) -lt $(docker container exec ${CONTAINER_NAME} /bin/bash -c "date -r ${DOCKER_HOME_DIR}${TEX_FILE_PATH} +%s") ]]; then
			docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_DIR_PATH} ${TEX_DIR_PATH}/../
		else
			# texを削除
			docker container exec --user root ${CONTAINER_NAME} bash -c "rm ${DOCKER_HOME_DIR}${TEX_FILE_PATH}"
			# pdfをコピーする
			docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_DIR_PATH} ${TEX_DIR_PATH}/../
		fi
	fi

	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "rm -rf ${DOCKER_HOME_DIR}/home"
}

function containerAttach {
	docker container exec -it ${CONTAINER_NAME} bash
}

function main {
	preExec
	texBuild
	fileFormat
	postExec
}

main