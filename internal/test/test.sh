# !/bin/bash

set -eu

path=$(readlink -f $(dirname ${0}))
cd $path

targets=($(ls ../../sample))
cd ../../sample

readonly NAME="latex-container"
readonly STYLE_DIR=$(readlink -f "../internal/style")
readonly SCRIPTS_DIR=$(readlink -f "../internal/scripts")
readonly ARCH=${1}

readonly DOCKER_HOME_DIR="/home/$(cat ../Dockerfile | grep "ARG DOCKER_USER_" | cut -d "=" -f 2)"

IS_FAILED=0

function pre_docker(){
	local -r target_tex_file_path=$1
	local -r target_dir_path=$(dirname ${target_tex_file_path})
	local -r target_dir_name=$(dirname ${target_tex_file_path} | rev | cut -d "/" -f 1 | rev)


	if [[ $(docker ps -a | grep -c ${NAME}) -eq 0 ]]; then
		docker container run \
		-it \
		--rm \
		-d \
		--name ${NAME} \
		${NAME}:${ARCH}
	fi
	docker container cp ${STYLE_DIR} ${NAME}:${DOCKER_HOME_DIR}
	docker container cp ${SCRIPTS_DIR} ${NAME}:${DOCKER_HOME_DIR}
	docker container cp ${target_dir_path} ${NAME}:${DOCKER_HOME_DIR}
	docker container exec --user root ${NAME}  /bin/bash -c "cp -n ${DOCKER_HOME_DIR}/style/* ${DOCKER_HOME_DIR}/${target_dir_name}"
	docker container exec --user root ${NAME}  /bin/bash -c "cp -n ${DOCKER_HOME_DIR}/scripts/* ${DOCKER_HOME_DIR}/${target_dir_name}"
}

function post_docker(){
	docker container kill ${NAME} > /dev/null
}

function exec_on_container(){
	local -r command=$1
	docker container exec --user root ${NAME} /bin/bash -c "${command}" 2> /dev/null
}

# 複数のtexファイルが同じディレクトリにある際に，メインのtexファイルを探索
function search_main_texfile(){
	local -r target_dir_path=$1

	local -r texfiles_cnt=$(find ${target_dir_path} -name "*.tex" -type f | wc -l)
	if [[ ${texfiles_cnt} -eq 0 ]]; then
		ERROR $LINENO "texfile not found"

	elif [[ ${texfiles_cnt} -eq 1 ]]; then
		echo $(find ${target_dir_path} -name "*.tex" -type f)
	else
		# メインのtex内にはdocumentclassが宣言されているはず
		local -r main_texfile_path=($(find ${target_dir_path} -name "*.tex" -type f -print | xargs grep '\\documentclass\[' | cut -d ":" -f 1))
		echo ${main_texfile_path}
	fi
}

function tex_build(){
	local -r target_texfile_path=$1
	local -r tex_dir_name=$(dirname ${target_texfile_path} | rev | cut -d "/" -f 1 | rev)
	docker container exec --user root ${NAME} /bin/bash -c "rm -f ${tex_dir_name}/*.pdf" &> /dev/null
	docker container exec --user root ${NAME} /bin/bash -c "cd ${tex_dir_name} && make all && make all" &> /dev/null
}

function test(){
	local -r target_texfile_path=$1
	pre_docker ${target_texfile_path} > /dev/null
	tex_build ${target_texfile_path} > /dev/null || true

	local -r target_dir_name=$(dirname ${target_texfile_path} | rev | cut -d "/" -f 1 | rev)

	# ファイル生成を確認
	local test_case="Generate PDF"
	if [[ -z $(exec_on_container "ls ${target_dir_name}/*.pdf") ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	# ファイルサイズ
	test_case="PDF is not empty"
	if [[ -z $(exec_on_container "wc -c < ${target_dir_name}/*.pdf") ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	# 文字数
	test_case="String In The PDF"
	if [[ $(exec_on_container "pdftotext ${target_dir_name}/*.pdf - " | wc -l) -eq 0 ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	# ログ
	test_case="LaTeX Log"
	if [[ $(exec_on_container "cat ${target_dir_name}/*.log" | grep -c "No pages of output" ) -ne 0 ]]; then
		FAILED "${test_case}"
	else
		CORRECT "${test_case}"
	fi

	post_docker
}

function ERROR(){
	local -r line=$1
	local -r comment=$2
	echo -e "[error] line: ${line}\n\t ${comment}"
	post_docker
	exit
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
		local target_tex_path=$(search_main_texfile $(readlink -f $target))
		test ${target_tex_path}
		echo
	done

	if [[ ${IS_FAILED} -eq 1 ]]; then
		exit 1
	fi
}



main