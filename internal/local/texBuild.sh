# !/bin/bash

# TEX_FILE_PATH: texファイルのパス = $1
# 	nullが指定されるとsemi-texから探索
# 	TEST_MODEに引数を渡すために使用
# 	絶対パスと相対パスのどちらでもOK

readonly DIR_PATH=$(readlink -f $(dirname ${0}))

source ${DIR_PATH}/config.sh

# readonly CONTAINER_NAME=latex-container
# readonly STYLE_DIR=internal/container/style
# readonly SCRIPTS_DIR=internal/local
# readonly DOCKER_HOME_DIR=/home/guest

if [[ -z $1 ]] || [[ $1 == "null" ]]; then
	readonly TEX_FILE_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh)
else
	if [[ -f $1 ]] || [[ -d $1 ]]; then
		readonly TEX_FILE_PATH=$(bash ${SCRIPTS_DIR}/search-main.sh $1)
	else
		echo "ファイルパスが不正: $1"
		exit 1
	fi
fi

[[ ! -z $(echo ${TEX_FILE_PATH} | grep -F '[ERROR]') ]] && echo ${TEX_FILE_PATH} && exit 1

# if [[ -z $2 ]]; then
# 	readonly USE_FORMAT=true
# else
# 	readonly USE_FORMAT=$2
# fi

TEST=${TEST:=0}

if [[ -z $ARCH ]]; then
	ARCH=$(uname -m)
fi

readonly TEX_DIR_PATH=$(dirname ${TEX_FILE_PATH})
readonly TEX_FILE_NAME=$(basename ${TEX_FILE_PATH})

function texBuild {
	echo "$(tput setaf 2)TEX PATH:$(tput sgr0): ${TEX_FILE_PATH}"
	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cd ${DOCKER_HOME_DIR}${TEX_DIR_PATH} && make all MY-MAIN=${TEX_FILE_NAME/.tex/} \
	&& sed -i 's@${DOCKER_HOME_DIR}@@g' ${TEX_FILE_NAME/.tex/.synctex}" # synctexのパスをコンテナ内からホストのパスに修正
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

	if [[ ${TEST} -eq 1 ]]; then
		docker container exec ${CONTAINER_NAME} /bin/bash -c "cd ${DOCKER_HOME_DIR}${TEX_DIR_PATH} && rm -f *.pdf *.dvi *.aux *.bbl"
	fi

	docker container exec --user root ${CONTAINER_NAME}  /bin/bash -c \
		"cp -n ${DOCKER_HOME_DIR}/internal/container/style/* ${DOCKER_HOME_DIR}${TEX_DIR_PATH} \
		&& cp -n ${DOCKER_HOME_DIR}/internal/container/scripts/* ${DOCKER_HOME_DIR}${TEX_DIR_PATH}"
}

function postExec {
	#ビルド中にローカルのtexファイルが更新されている場合，ローカルのtexファイルを上書きしない
	if [[ ${TEST} -ne 1 ]]; then
		if [[ $(date -r ${TEX_FILE_PATH} +%s) -lt $(docker container exec ${CONTAINER_NAME} /bin/bash -c "date -r ${DOCKER_HOME_DIR}${TEX_FILE_PATH} +%s") ]]; then
			docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH} ${TEX_DIR_PATH}
		fi

		# 成果物をホストにコピー
		# || trueはコマンド失敗時に，その行で実行が止まらないようにするため
		#  実行が止まるとそれ以降の行で成果物が取り出せなくなる
		docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH/.tex/.pdf} ${TEX_DIR_PATH} || true
		docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH/.tex/.log} ${TEX_DIR_PATH} || true
		docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH/.tex/.aux} ${TEX_DIR_PATH} || true
		docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH/.tex/.dvi} ${TEX_DIR_PATH} || true
		docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH/.tex/.synctex} ${TEX_DIR_PATH} || true
		docker container cp ${CONTAINER_NAME}:${DOCKER_HOME_DIR}${TEX_FILE_PATH/.tex/.bbl} ${TEX_DIR_PATH} || true
		# if [[ $(docker container exec -i ${CONTAINER_NAME} /bin/bash -c "find ${DOCKER_HOME_DIR}/home -type d | wc -l") -lt 100 ]]; then
		# 	docker container exec ${CONTAINER_NAME} /bin/bash -c "rm -rf ${DOCKER_HOME_DIR}/home"
		# else
		# 	echo "想定外の場所をrmしようとしている可能性があります"
		# 	exit 1
		# fi
	fi
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

# echo ${TEX_FILE_NAME}
# echo ${TEX_FILE_PATH}
# echo ${TEX_FILE_NAME/.tex/.pdf}