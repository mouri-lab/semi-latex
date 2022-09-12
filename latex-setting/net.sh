# !/bin/sh

NEW_LINK="http://ftp.riken.jp/Linux/ubuntu/"

readonly LINK=$(cat /etc/apt/sources.list | grep -v "#" | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)
echo $LINK
sed -i "s-${LINK}-${NEW_LINK}-g" /etc/apt/sources.list