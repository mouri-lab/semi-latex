# !/bin/bash


readonly tex_file=$(sed -n 2p lint.txt | rev | cut -d "/" -f 1 | rev)

readonly host_tex_path=$1

set -eu


[[ -z $host_tex_path ]] && exit 1

# for_loop_max=2
for_loop_max=$(cat lint.txt | grep -c -E "([0-9])+:([0-9])+")
for ((i=0; i < $for_loop_max; i++)); do
	target=$(cat lint.txt | grep -v ${tex_file} | grep -E "([0-9])+:([0-9])+" | head -n1 | sed -e "s/ \+/,/g" | cut -d "," -f 2 )
	if [[ -z $target ]]; then
		break
	fi
	sed -i "s@${target}@\n${host_tex_path}:${target}\n\t@" lint.txt
done
unset for_loop_max

sed -i "s@^ \+@ @" lint.txt
cat lint.txt

# sed -E s@"([0-9])+:([0-9])+"@"hoge/\1: \2"@ lint.txt