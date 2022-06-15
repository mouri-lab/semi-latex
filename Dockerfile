# FROM nobodyxu/apt-fast:latest-ubuntu-bionic AS base
FROM amd64/ubuntu:20.04 AS latex

ENV DEBIAN_FRONTEND noninteractive
# ユーザーを作成
ARG DOCKER_USER_=null

RUN apt-get update

# パッケージインストールで参照するサーバを日本サーバに変更
# デフォルトのサーバは遠いので通信速度が遅い
RUN apt-get install -y apt-utils
RUN apt-get install -y perl --no-install-recommends \
    && perl -p -i.bak -e 's%(deb(?:-src|)\s+)https?://(?!archive\.canonical\.com|security\.ubuntu\.com)[^\s]+%$1http://ftp.riken.jp/Linux/ubuntu/%' /etc/apt/sources.list

# ターミナルで日本語の出力を可能にするための設定
RUN apt-get update \
    &&  apt-get install -y \
    language-pack-ja-base \
    language-pack-ja \
    fonts-noto-cjk \
    fcitx-mozc

RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:jp
ENV LC_ALL ja_JP.UTF-8
RUN update-locale LANG=ja_JP.UTF-8

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezon

# 実行のためのパッケージ
RUN apt-get install -y \
    make \
    evince \
    xdvik-ja \
    imagemagick \
    texlive-fonts-extra \
    texlive-latex-extra \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-lang-cjk \
    texlive-lang-japanese \
    inkscape \
    librsvg2-bin \
    &&  apt-get clean


ENV DIRPATH home/${DOCKER_USER_}
WORKDIR $DIRPATH
# ユーザ設定
RUN useradd ${DOCKER_USER_}
RUN chown -R ${DOCKER_USER_} /${DIRPATH}

USER ${DOCKER_USER_}


FROM latex AS textlint

USER root

RUN apt-get install -y nodejs \
    npm \
    curl \
    wget

RUN npm install n -g -y \
    && n lts

RUN npm init --yes \
    && npm install textlint \
    textlint-rule-preset-ja-technical-writing \
    textlint-rule-preset-ja-spacing \
    textlint-rule-preset-jtf-style \
    textlint-rule-preset-ja-engineering-paper \
    textlint-plugin-latex2e

# ”はじめに”と”おわりに”を漢字変換しないよう，ルールを変更
RUN sed -i "1084,1085d" node_modules/prh/prh-rules/media/WEB+DB_PRESS.yml \
    && sed -i "s;おわ[^0-9][^0-9]らりるれろ;おわ\([らるれろ;g" node_modules/prh/prh-rules/media/WEB+DB_PRESS.yml

ENV GTK_IM_MODULE=xim \
    QT_IM_MODULE=fcitx \
    XMODIFIERS=@im=fcitx \
    DefalutIMModule=fcitx

USER ${DOCKER_USER_}
