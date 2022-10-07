FROM node:16.17.1 AS node
FROM amd64/ubuntu:20.04 AS latex

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive
# ユーザーを作成
ARG DOCKER_USER_=guest

COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/

ARG APT_LINK=http://ftp.riken.jp/Linux/ubuntu/
RUN sed -i "s-$(grep -v "#" /etc/apt/sources.list | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-${APT_LINK}-g" /etc/apt/sources.list

RUN apt-get -q update &&\
    apt-get -q install -y --no-install-recommends software-properties-common \
    && add-apt-repository ppa:apt-fast/stable \
    && apt-get -q update \
    && apt-get -q install -y --no-install-recommends apt-fast \
    && apt-get purge -y software-properties-common \
    && apt-get clean

# ターミナルで日本語の出力を可能にするための設定
RUN apt-fast update \
    && apt-fast install -y --no-install-recommends \
    language-pack-ja-base \
    language-pack-ja \
    fonts-noto-cjk \
    fcitx-mozc

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:jp
ENV LC_ALL ja_JP.UTF-8
RUN locale-gen ja_JP.UTF-8 && \
    update-locale LANG=ja_JP.UTF-8

# 実行のためのパッケージ
RUN apt-fast install -y --no-install-recommends \
    make \
    evince \
    xdvik-ja \
    imagemagick \
    texlive-fonts-extra \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-lang-cjk \
    texlive-lang-japanese \
    # svg, epsの変換ツール
    inkscape \
    librsvg2-bin \
    # pdbをtextに変換
    poppler-utils \
    # textlint用のnpm
    npm \
    curl \
    wget \
    &&  kanji-config-updmap-sys auto

# 推奨パッケージをインストール
RUN apt-fast install -y \
    texlive-extra-utils


ENV DIRPATH /home/${DOCKER_USER_}
WORKDIR $DIRPATH

# ユーザ設定
RUN useradd ${DOCKER_USER_} \
    && chown -R ${DOCKER_USER_} ${DIRPATH}

RUN npm install textlint \
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
RUN apt-fast update &&\
    apt-fast upgrade -y &&\
    apt-fast clean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER ${DOCKER_USER_}
