#!/bin/bash
set -eu

# macOSはBashコマンドがLinuxのものと互換性がないので，一部のスクリプトが動作しない
# なのでmacOSではスクリプト実行用のコンテナ内でスクリプトを動作させることで回避

readonly CONTAINER_NAME=python-container
readonly CONTAINER_USER_DIR=/home/nobody
readonly DOCKER_IMAGE=python:3.9.18-slim


# このファイルが格納されているディレクトリの絶対パス
readonly DIR_PATH=$(readlink -f $(dirname ${0}) | rev | cut -d "/" -f 4- | rev)


[[ -z $(docker ps | grep ${CONTAINER_NAME}) ]] \
	&& docker run -it --rm -d --name ${CONTAINER_NAME} -v /home/taka/git/semi-latex:${CONTAINER_USER_DIR}/semi-latex:ro ${DOCKER_IMAGE}

temp=$(docker exec ${CONTAINER_NAME} bash -c "cd ${CONTAINER_USER_DIR} && python3 semi-latex/internal/scripts/target_tex_find.py semi-latex")
echo ${DIR_PATH}/${temp}
