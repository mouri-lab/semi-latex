# !/bin/bash

set -eu

# texで複数回のビルドを行う判断をする
# 参照箇所で??となっている場合には再ビルドを行う（上限回数あり）

# コンテナ内で実行される前提で動作

readonly CONTAINER_NAME=$1
readonly TEX_DIR=$2
readonly TEX_FILE=$3
readonly PDF_FILE=$(echo ${TEX_FILE} | sed s/.tex/.pdf/)

docker container exec --user root ${CONTAINER_NAME} /bin/bash -c "cd ${TEX_DIR} && make --trace all MY-MAIN=$(echo ${TEX_FILE} | sed s/.tex//) PLATEX='platex -halt-on-error -file-line-error'"

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