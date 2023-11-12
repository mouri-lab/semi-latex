# !/bin/bash

set -eu

path=$(readlink -f $(dirname ${0}))
cd $path

targets=($(ls ../../sample))
cd ../../sample

readonly NAME="latex-container"
readonly STYLE_DIR=$(readlink -f "../internal/style")
readonly SCRIPTS_DIR=$(readlink -f "../internal/scripts")
readonly ARCH=$(uname -m)

readonly DOCKER_HOME_DIR="/home/$(cat ../Dockerfile | grep "ARG DOCKER_USER_" | cut -d "=" -f 2)"

function pre_docker(){
	local -r target_tex_dir=$1

	if [[ $(docker ps -a | grep -c ${NAME}) -eq 0 ]]; then\
		docker container run \
		-it \
		--rm \
		-d \
		--name ${NAME} \
		${NAME}:${ARCH};\
	fi
	docker container cp ${STYLE_DIR} ${NAME}:${DOCKER_HOME_DIR}
	docker container cp ${SCRIPTS_DIR} ${NAME}:${DOCKER_HOME_DIR}
	docker container cp ${target_tex_dir} ${NAME}:${DOCKER_HOME_DIR}
	docker container exec --user root ${NAME}  /bin/bash -c "cp -n ${DOCKER_HOME_DIR}/style/* ${DOCKER_HOME_DIR}/$(basename ${target_tex_dir})"
	docker container exec --user root ${NAME}  /bin/bash -c "cp -n ${DOCKER_HOME_DIR}/scripts/* ${DOCKER_HOME_DIR}/$(basename ${target_tex_dir})"
}

function post_docker(){
	docker container kill ${NAME}
}

# 複数のtexファイルが同じディレクトリにある際に，メインのtexファイルを探索
function search_main_texfile(){
	local -r target_dir_path=$1

	local texfiles=($(find ${target_dir_path} -name "*.tex" -type f))




}

function tex_build(){
	local -r target_tex_dir=$1
	pre_docker $(readlink -f $(basename ${target_tex_dir}))

	local -r texfile_cnt=$(find ${target_tex_dir} -name "*.tex" -type f | wc -l)

	if [[ $texfile_cnt -eq 0 ]]; then

		return 0

	fi


	if [[ $texfile_cnt -eq 1 ]]; then

		local -r target_texfile=$(basename $(find $target_tex_dir -name "*.tex" -type f))
		bash ${SCRIPTS_DIR}/build.sh ${NAME} ${target_texfile} $(basename ${target_tex_dir})

	else

		local -r target_texfile=$(basename $(grep -r "\include{" $(target_tex_dir) | cut -d ":" -f 1 | head -n1))
		bash ${SCRIPTS_DIR}/build.sh ${NAME} main.tex $(basename ${target_tex_dir})

	fi



	post_docker
}


function main(){
	for target in ${targets[@]}; do
		echo $target

		# echo $(readlink -f $(basename ${target}))

		# tex_build $(readlink -f $target)
		search_main_texfile $(readlink -f $target)

		# 卒論などの複数のtexファイルを結合している場合
		# if [[ $(ls $target | grep -c main.tex) -eq 1 ]]; then

		# else

		# fi
	done
}



main