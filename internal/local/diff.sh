# !/bin/bash

# OLD_PATH: 古いtexfile = $1
# NEW_PATH: 新しいtexfile = $2
# TEST_MODE: bool = $3

readonly CONTAINER_NAME=latex-container
readonly STYLE_DIR=internal/container/style
readonly SCRIPTS_DIR=internal/local
readonly DOCKER_HOME_DIR=/home/guest
readonly ARCH=$(uname -m)


# readonly OLD_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh $1)

# 比較元のtexファイルのパス
readonly OLD_PATH=${old}
[[ ! -z $(echo ${OLD_PATH} | grep -F "[ERROR]") ]] && echo ${OLD_PATH} && exit 1
if [[ ! -f $OLD_PATH ]]; then
    echo "ファイルパスが不正 old: $1"
    exit 1
fi


# readonly NEW_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh $2)
# [[ ! -z $(echo ${NEW_PATH} | grep "[ERROR]") ]] && echo ${NEW_PATH} && exit 1

# 更新したtexファイルのパス
# 空の場合は最新のtexファイルを探索
readonly NEW_PATH=${new:=$(bash ${SCRIPTS_DIR}/search-main.sh)}
if [[ ! -f $NEW_PATH ]]; then
    echo "ファイルパスが不正 new: $2"
    exit 1
fi

# TEST_MODE: ビルドした成果物をローカルに保存しない
if [[ -z $3 ]]; then
	readonly TEST_MODE=false
else
	readonly TEST_MODE=$3
fi

readonly DIR_PATH=$(readlink -f $(dirname ${0}))
readonly TEX_DIR_PATH=$(dirname ${NEW_PATH})

set -u

function makeDiff {
	docker container cp ${OLD_PATH} ${CONTAINER_NAME}:${DOCKER_HOME_DIR}
	docker container cp ${NEW_PATH} ${CONTAINER_NAME}:${DOCKER_HOME_DIR}

    # diff.texを生成
    docker container exec --user root ${CONTAINER_NAME} /bin/bash -c \
        "latexdiff --graphics-markup=none -e utf8 -t CFONT $(basename ${OLD_PATH}) $(basename ${NEW_PATH}) > diff.tex"

    # 環境をコンテナにコピー
    docker container exec ${CONTAINER_NAME} /bin/bash -c "mkdir -p ${DOCKER_HOME_DIR}/${TEX_DIR_PATH}"
	docker container cp ${TEX_DIR_PATH} ${CONTAINER_NAME}:${DOCKER_HOME_DIR}/${TEX_DIR_PATH}/../
	docker container exec ${CONTAINER_NAME} /bin/bash -c \
		"cp -n ${DOCKER_HOME_DIR}/internal/container/style/* ${DOCKER_HOME_DIR}/${TEX_DIR_PATH} \
		&& cp -n ${DOCKER_HOME_DIR}/internal/container/scripts/* ${DOCKER_HOME_DIR}/${TEX_DIR_PATH}"

	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c \
        "rm ${DOCKER_HOME_DIR}/${TEX_DIR_PATH}/*.tex"
	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c \
        "cp ${DOCKER_HOME_DIR}/diff.tex ${DOCKER_HOME_DIR}/${TEX_DIR_PATH}"
	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c \
        "cd ${DOCKER_HOME_DIR}/${TEX_DIR_PATH} && make all && make all && make all"
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
}

function postExec {
	#ビルド中にローカルのtexファイルが更新されている場合，ローカルのtexファイルを上書きしない
	if [[ ${TEST_MODE} != true ]]; then
        docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}/${TEX_DIR_PATH}/diff.pdf ${TEX_DIR_PATH}/diff.pdf
        docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}/${TEX_DIR_PATH}/diff.tex ${TEX_DIR_PATH}/diff.tex
        docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}/${TEX_DIR_PATH}/diff.log ${TEX_DIR_PATH}/diff.log
	fi
	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "rm -rf ${DOCKER_HOME_DIR}/home *.tex"
}

function containerAttach {
	docker container exec -it ${CONTAINER_NAME} bash
}

function main {
	preExec
    makeDiff
	postExec
}

main