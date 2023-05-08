#!/bin/bash
set -eu

# macOSはBashコマンドがLinuxのものと互換性がないので，一部のスクリプトが動作しない
# なのでmacOSではスクリプト実行用のコンテナ内でスクリプトを動作させることで回避

readonly CONTAINER_NAME=shell-for-mac

readonly CONTAINER_USER_DIR=/home/nobody


# このファイルが格納されているディレクトリの絶対パス
readonly DIR_PATH=$(readlink -f $(dirname ${0}) | rev | cut -d "/" -f 1- | rev )



if [[ -z $(docker images | grep ${CONTAINER_NAME}) ]]; then

	DOCKER_BUILDKIT=1 docker image build -t ${CONTAINER_NAME} \
	--pull \
	--force-rm=true \
	--no-cache=true \
	-f Dockerfile_forMac \
	${DIR_PATH}/../../

	[[ -z $(docker images | grep ${CONTAINER_NAME}) ]] && exit 0

fi

# echo $DIR_PATH

if [[ -z $(docker ps | grep ${CONTAINER_NAME}) ]]; then

	docker run -it --rm -d \
		--name ${CONTAINER_NAME}\
		-v ${DIR_PATH}/../../../semi-latex:${CONTAINER_USER_DIR}:ro \
		${CONTAINER_NAME}

fi

result=$(docker exec -it ${CONTAINER_NAME} bash -c "cd ${CONTAINER_USER_DIR} && bash internal/scripts/file-explorer.sh" | tail -n 1)

echo $result | sed -e "s@${CONTAINER_USER_DIR}/@@g"