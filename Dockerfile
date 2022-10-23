FROM node:18.11.0-slim AS node
FROM amd64/ubuntu:20.04 AS textlint

ENV DEBIAN_FRONTEND noninteractive

COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/

ARG DOCKER_USER=guest


ENV DIRPATH /home/${DOCKER_USER}
WORKDIR $DIRPATH

# ユーザ設定
RUN useradd ${DOCKER_USER} \
    && chown -R ${DOCKER_USER} ${DIRPATH}

ARG APT_LINK=http://ftp.riken.jp/Linux/ubuntu/
RUN sed -i "s-$(grep -v "#" /etc/apt/sources.list | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-${APT_LINK}-g" /etc/apt/sources.list
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    npm \
    && apt-get -y clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*


RUN npm install textlint \
    textlint-rule-preset-ja-technical-writing \
    textlint-rule-preset-ja-spacing \
    textlint-rule-preset-jtf-style \
    textlint-rule-preset-ja-engineering-paper \
    textlint-plugin-latex2e\
    && npm cache clean --force

RUN rm $(find / -name "*.def" -type f)



FROM amd64/ubuntu:20.04 AS latex

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive
# ユーザーを作成
ARG DOCKER_USER_=guest


ARG APT_LINK=http://ftp.riken.jp/Linux/ubuntu/
RUN sed -i "s-$(grep -v "#" /etc/apt/sources.list | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-${APT_LINK}-g" /etc/apt/sources.list


# ターミナルで日本語の出力を可能にするための設定
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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
RUN apt-get install -y --no-install-recommends \
    make \
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
    # pdfをtextに変換
    poppler-utils \
    &&  kanji-config-updmap-sys auto

# 推奨パッケージをインストール
RUN apt-get install -y \
    texlive-extra-utils \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*


ENV DIRPATH /home/${DOCKER_USER_}
WORKDIR $DIRPATH

RUN useradd ${DOCKER_USER_} \
    && chown -R ${DOCKER_USER_} ${DIRPATH}

USER ${DOCKER_USER_}

COPY --from=textlint $DIRPATH/ $DIRPATH/
COPY --from=textlint /usr/local/bin/ /usr/local/bin/

COPY media/semi-rule.yml ${DIRPATH}/node_modules/prh/prh-rules/media/
COPY media/WEB+DB_PRESS.yml ${DIRPATH}/node_modules/prh/prh-rules/media/
COPY .textlintrc ${DIRPATH}/

ENV PATH $PATH:${DIRPATH}/node_modules/textlint/bin

