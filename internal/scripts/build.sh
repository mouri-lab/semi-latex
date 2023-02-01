# !/bin/bash

set -eu

# texで複数回のビルドを行う判断をする
# 参照箇所で??となっている場合には再ビルドを行う（上限回数あり）

# コンテナ内で実行される前提で動作

readonly NAME=$1
readonly TEX_DIR=$2
readonly TEX_FILE=$(echo $3 | sed s/.tex/.pdf/)

docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && make all"


# 4回もビルドして??が残るのであれば参照ミスと判断
for_loop_max=3
for ((i=0; i < ${for_loop_max}; i++)); do

	docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && pdftotext ${TEX_FILE} ../pdf.txt"

	if [[ $(docker container exec --user root ${NAME} /bin/bash -c "cat pdf.txt | grep -c '??'") > 0 ]]; then

		docker container exec --user root ${NAME} /bin/bash -c "cd ${TEX_DIR} && make all"

	else

		docker container exec --user root ${NAME} /bin/bash -c "rm -f \
		$(docker container exec --user root ${NAME} /bin/bash -c  "find . -name "*.xbb" -type f" | sed -z 's/\n/ /g' )"

		exit 0

	fi

done
unset for_loop_max