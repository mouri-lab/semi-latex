# !/bin/bash

set -u

# texで複数回のビルドを行う判断をする
# 参照箇所で??となっている場合には再ビルドを行う（上限回数あり）

# コンテナ内で実行される前提で動作

readonly CONTAINER_NAME=$1
readonly TEX_DIR=$2
TEX_FILE=$3
readonly PDF_FILE=$(echo ${TEX_FILE} | sed s/.tex/.pdf/)
TEX_FILE_PATH=$4

readonly DIR_PATH=$(readlink -f $(dirname ${0}))
echo ${DIR_PATH}
cd ${DIR_PATH}

TEX_FILE_PATH=$(bash search-main.sh)
echo "target: ${TEX_FILE_PATH}"
TEX_FILE=$(basename ${TEX_FILE_PATH})

docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cd ${TEX_DIR} && make --trace all MY-MAIN=$(echo ${TEX_FILE} | sed s/.tex//)"

exit 0

# 4回もビルドして??が残るのであれば参照ミスと判断
for_loop_max=3
for ((i=0; i < ${for_loop_max}; i++)); do

	docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cd ${TEX_DIR} && pdftotext ${PDF_FILE} ../pdf.txt"

	if [[ $(docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cat pdf.txt | grep -c '??'") > 0 ]]; then

		docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cd ${TEX_DIR} && make all "

	else

		docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "rm -f \
		$(docker container exec --user root ${CONTAINER_NAME} /bin/bash -c  "find . -CONTAINER_NAME "*.xbb" -type f" | sed -z 's/\n/ /g' )"

		exit 0

	fi

done
unset for_loop_max