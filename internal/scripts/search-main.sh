#!/bin/bash
set -e

# macOSはBashコマンドがLinuxのものと互換性がないので，一部のスクリプトが動作しない
# なのでmacOSではスクリプト実行用のコンテナ内でスクリプトを動作させることで回避

readonly CONTAINER_NAME=python-container
readonly CONTAINER_USER_DIR=/home/nobody
readonly DOCKER_IMAGE=python:3.10-alpine

readonly TEX_FILE_PATH=$1


# このファイルが格納されているディレクトリの絶対パス
readonly DIR_PATH=$(readlink -f $(dirname ${0}) | rev | cut -d "/" -f 4- | rev)

[[ -z $(docker ps | grep ${CONTAINER_NAME}) ]] \
	&& docker run -it -d --rm --name ${CONTAINER_NAME} -v ${DIR_PATH}/semi-latex:${CONTAINER_USER_DIR}/semi-latex:ro ${DOCKER_IMAGE}

temp=$(docker exec ${CONTAINER_NAME} /bin/ash -c "cd ${CONTAINER_USER_DIR} && python3 semi-latex/internal/scripts/target_tex_find.py semi-latex ${TEX_FILE_PATH}")


echo ${DIR_PATH}/${temp}
