#!/bin/bash
set -eu

# macOSはBashコマンドがLinuxのものと互換性がないので，一部のスクリプトが動作しない
# なのでmacOSではスクリプト実行用のコンテナ内でスクリプトを動作させることで回避

readonly CONTAINER_NAME=bash-container

readonly CONTAINER_USER_DIR=/home/nobody


# このファイルが格納されているディレクトリの絶対パス
readonly DIR_PATH=$(readlink -f $(dirname ${0}) | rev | cut -d "/" -f 1- | rev )


if [[ -z $(docker ps | grep ${CONTAINER_NAME}) ]]; then

	docker run -it --rm -d \
		--name ${CONTAINER_NAME}\
		-v ${DIR_PATH}/../../../semi-latex:${CONTAINER_USER_DIR}:ro \
		bash:devel-alpine3.18

fi

result=$(docker exec -it ${CONTAINER_NAME} bash -c "cd ${CONTAINER_USER_DIR} && bash internal/scripts/file-explorer.sh" | tail -n 1)

echo $result | sed -e "s@${CONTAINER_USER_DIR}/@@g"