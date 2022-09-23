# FROM nobodyxu/apt-fast:latest-ubuntu-bionic AS base
FROM amd64/ubuntu:20.04 AS latex

ENV DEBIAN_FRONTEND noninteractive
# ユーザーを作成
ARG DOCKER_USER_=guest

ARG APT_LINK=http://ftp.riken.jp/Linux/ubuntu/
RUN sed -i "s-$(cat /etc/apt/sources.list | grep -v "#" | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-${APT_LINK}-g" /etc/apt/sources.list

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
    # svg, epsの変換ツール
    inkscape \
    librsvg2-bin \
    # pdbをtextに変換
    poppler-utils \
    &&  apt-get clean \
    &&  kanji-config-updmap-sys auto


ENV DIRPATH /home/${DOCKER_USER_}
WORKDIR $DIRPATH

# ユーザ設定
RUN useradd ${DOCKER_USER_}
RUN chown -R ${DOCKER_USER_} ${DIRPATH}

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

ENV GTK_IM_MODULE=xim \
    QT_IM_MODULE=fcitx \
    XMODIFIERS=@im=fcitx \
    DefalutIMModule=fcitx

# 研究室用のカスタムルールをコピー
COPY media/semi-rule.yml ${DIRPATH}/node_modules/prh/prh-rules/media/
COPY media/WEB+DB_PRESS.yml ${DIRPATH}/node_modules/prh/prh-rules/media/
COPY .textlintrc ${DIRPATH}/

ARG TS
RUN apt-get update &&\
    apt-get upgrade -y

USER ${DOCKER_USER_}
