# !/bin/bash

set -eu

readonly path=$(readlink -f $(dirname ${0}))
readonly SCRIPT_DIR_PATH=$(dirname ${path})
cd $path


targets=($(ls ../../sample))
cd ../../sample

readonly NAME="latex-container"
readonly STYLE_DIR=$(readlink -f "../internal/container/style")
readonly SCRIPTS_DIR=$(readlink -f "../internal/local")

if [[ -z $DOCKER_TAG ]]; then
	DOCKER_TAG="latest"
fi
readonly DOCKER_HOME_DIR="/home/$(cat ../Dockerfile | grep "ARG DOCKER_USER_" | cut -d "=" -f 2)"

IS_FAILED=0

function post_docker(){
	docker container kill ${NAME} > /dev/null
}

function exec_on_container(){
	local -r command=$1
	docker container exec -i ${NAME} /bin/bash -c "cd ${DOCKER_HOME_DIR} && ${command}" 2> /dev/null
}

function containerAttach {
	docker container exec -it ${NAME} bash
}

function test(){
	local -r target_texdir_path=$1
	# テスト実行
	# 標準出力と標準エラー出力はCLIが崩れるので出力しない
	# テスト結果は後ろで確認するので，このコマンドは常に成功させる（そうしないと他のテストが実行されない)）
	TEST=1 DOCKER_TAG=${DOCKER_TAG} bash ${SCRIPTS_DIR}/texBuild.sh ${target_texdir_path} 1>/dev/null 2>/dev/null || true

	local -r target_dir_name=$(dirname ${target_texdir_path} | rev | cut -d "/" -f 1 | rev)
	local -r target_file_path=$(bash ${SCRIPTS_DIR}/search-main.sh ${target_texdir_path})
	local -r target_pdf_path=${target_file_path/.tex/.pdf}

	# ファイル生成を確認
	local test_case="Generate PDF"
	if [[ -z $(exec_on_container "ls ${DOCKER_HOME_DIR}${target_pdf_path}") ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	# ファイルサイズ
	test_case="PDF is not empty"
	if [[ -z $(exec_on_container "wc -c < ${DOCKER_HOME_DIR}${target_pdf_path}") ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	# 文字数
	test_case="String In The PDF"
	if [[ $(exec_on_container "pdftotext ${DOCKER_HOME_DIR}${target_pdf_path} - " | wc -l) -eq 0 ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	# ログ
	test_case="LaTeX Log"
	if [[ $(exec_on_container "cat ${DOCKER_HOME_DIR}${target_file_path/.tex/.log}" | grep -c "Output written on" ) -eq 0 ]]; then
		FAILED "${test_case}"
		docker cp ${NAME}:${DOCKER_HOME_DIR}${target_file_path/.tex/.log} ${target_file_path/.tex/.log}
	else
		CORRECT "${test_case}"
	fi

	post_docker
}

function FAILED(){
	local -r comment=$1
	echo -e "$(tput setaf 1)[  FAILED  ]$(tput sgr0) ${comment}"
	IS_FAILED=1
}

function CORRECT(){
	local -r comment=$1
	echo -e "$(tput setaf 2)[       OK ]$(tput sgr0) ${comment}"
}

function main(){
	echo -e "$(tput setaf 2)[==========]$(tput sgr0) Running ${#targets[@]} tests"
	for target in ${targets[@]}; do
		echo -e "$(tput setaf 2)[----------]$(tput sgr0) Target: ${target}"
		local target_tex_path=$(readlink -f $target)
		test ${target_tex_path}
		echo
	done

	if [[ ${IS_FAILED} -eq 1 ]]; then
		exit 1
	fi
}



main