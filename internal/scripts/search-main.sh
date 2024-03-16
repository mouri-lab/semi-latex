#!/bin/bash
set -e

# macOSはBashコマンドがLinuxのものと互換性がないので，一部のスクリプトが動作しない
# なのでmacOSではスクリプト実行用のコンテナ内でスクリプトを動作させることで回避

readonly CONTAINER_NAME=python-container
readonly CONTAINER_USER_DIR=/home/nobody
readonly DOCKER_IMAGE=python:3.10-alpine

# 絶対パス
if [[ -z $1 ]]; then
	readonly TEX_FILE_PATH=$1
else
	readonly TEX_FILE_PATH=$(readlink -f $1)
fi

# このファイルが格納されているディレクトリの絶対パス
# ${path}/semi-latex/
readonly DIR_PATH=$(readlink -f $(dirname ${0}) | rev | cut -d "/" -f 3- | rev)

readonly WORK_DIR=${CONTAINER_USER_DIR}${DIR_PATH}

[[ -z $(docker ps | grep ${CONTAINER_NAME}) ]] \
	&& docker run -i -d --rm --name ${CONTAINER_NAME} -v ${DIR_PATH}:${WORK_DIR}:ro ${DOCKER_IMAGE}

if [[ -z ${TEX_FILE_PATH} ]]; then

	temp=$(docker exec ${CONTAINER_NAME} /bin/ash -c "cd ${WORK_DIR} && python3 ${WORK_DIR}/internal/scripts/target_tex_find.py ${CONTAINER_USER_DIR} ${WORK_DIR}")

else

	temp=$(docker exec ${CONTAINER_NAME} /bin/ash -c "cd ${WORK_DIR} && python3 ${WORK_DIR}/internal/scripts/target_tex_find.py ${CONTAINER_USER_DIR} ${WORK_DIR} ${TEX_FILE_PATH}")

fi

echo ${temp}