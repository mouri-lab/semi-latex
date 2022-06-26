# !/bin/bash

# サンプルのtexファイルの内容を削除する

set -eu

head=$(grep -n "ここから消して下さい" workspace/semi.tex | cut -d ":" -f 1)
# head=$(expr ${head} + 1)
tail=$(grep -n "ここまで消して下さい" workspace/semi.tex | cut -d ":" -f 1)

sed -i "${head},${tail}d" workspace/semi.tex

head=$(grep -n "begin{abstract}" workspace/semi.tex | cut -d ":" -f 1)
head=$(expr ${head} + 1)
tail=$(grep -n "end{abstract}" workspace/semi.tex | cut -d ":" -f 1)
tail=$(expr ${tail} - 1)
sed -i "${head},${tail}d" workspace/semi.tex
sed -i "s/begin{abstract}/begin{abstract}\n/" workspace/semi.tex
sed -i "s/maketitle/maketitle\n\n\\\section{はじめに}/" workspace/semi.tex