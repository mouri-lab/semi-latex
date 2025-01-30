#!/bin/bash

#コンテナ内で実行
# diff.texを差分のみ赤字にする

HOME_DIR=$1

sed -i -e 's/\\providecommand{\\DIFadd}\[1\]{{\\protect\\color{blue} \\sf \#1}}/\\providecommand{\\DIFadd}[1]{{\\protect\\color{red}\#1}}/' ${HOME_DIR}/diff.tex

sed -i -e 's/\\providecommand{\\DIFdel}\[1\]{{\\protect\\color{red} \\scriptsize \#1}}/\\providecommand{\\DIFdel}[1]{{}}/' ${HOME_DIR}/diff.tex