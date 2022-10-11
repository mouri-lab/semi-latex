#!/bin/bash

# set -e

# 最後に更新されたtexファイルを探索

tex_files=()
tex_files+=($(readlink -f $(find . -name "*.tex" -type f)))


file_date=()
file_date+=($(stat ${tex_files[@]} | grep Modify | cut -d " " -f 2,3 | sed -e "s@ @@g" -e "s@-@@g" -e "s@:@@g" -e "s@@@g"))
# echo ${file_date[@]}

temp=()
for_loop_max=${#file_date[@]}
for ((i=0; i < for_loop_max; i++)); do
  temp+=("${tex_files[$i]}@${file_date[$i]}")
done
unset for_loop_max

printf "%s\n" "${temp[@]}" | sort -t "@" -k 2 -r -n | head -n1 | cut -d "@" -f 1