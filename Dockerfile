FROM --platform=amd64 node:20-slim AS node
FROM amd64/ubuntu:20.04 AS textlint

ENV DEBIAN_FRONTEND noninteractive

COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/

ARG DOCKER_USER=guest


ARG APT_LINK=http://www.ftp.ne.jp/Linux/packages/ubuntu/archive/
RUN sed -i "s-$(grep -v "#" /etc/apt/sources.list | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-${APT_LINK}-g" /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    npm \
    && apt-get -y clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY ./internal/custom-rules/textlint-rule-ja-custom-ng-word /textlint-rule-ja-custom-ng-word
RUN cd /textlint-rule-ja-custom-ng-word \
    && npm install

RUN npm install -g \
    textlint \
    textlint-rule-preset-ja-technical-writing \
    textlint-rule-preset-ja-spacing \
    textlint-rule-preset-jtf-style \
    textlint-rule-preset-ja-engineering-paper \
    textlint-plugin-latex2e \
    textlint-rule-ja-no-weak-phrase \
    @textlint/ast-node-types \
    /textlint-rule-ja-custom-ng-word


# RUN rm $(find / -name "*.def" -type f) $(find / -name "*.lz4" -type f )

FROM amd64/ubuntu:20.04 AS latex

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive
# ユーザーを作成
ARG DOCKER_USER_=guest

ARG APT_LINK=http://www.ftp.ne.jp/Linux/packages/ubuntu/archive/
RUN sed -i "s-$(grep -v "#" /etc/apt/sources.list | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-${APT_LINK}-g" /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    language-pack-ja-base=1:20.04+20220818 \
    language-pack-ja=1:20.04+20220818 \
    fonts-noto-cjk=1:20190410+repack1-2 \
    fcitx-mozc=2.23.2815.102+dfsg-8ubuntu1

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:jp
ENV LC_ALL ja_JP.UTF-8
RUN locale-gen ja_JP.UTF-8 && \
    update-locale LANG=ja_JP.UTF-8

RUN apt-get install -y --no-install-recommends \
    make \
    xdvik-ja \
    imagemagick \
    # svg, epsの変換ツール
    inkscape \
    librsvg2-bin \
    # pdfをtextに変換
    poppler-utils \
    texlive=2019.20200218-1 \
    texlive-fonts-extra=2019.202000218-1 \
    texlive-latex-extra=2019.202000218-1 \
    texlive-fonts-recommended=2019.20200218-1 \
    texlive-lang-cjk=2019.20200218-1 \
    texlive-lang-japanese=2019.20200218-1 \
    &&  kanji-config-updmap-sys auto

# 推奨パッケージをインストール
RUN apt-get install -y \
    texlive-extra-utils=2019.202000218-1 \
    latexdiff \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*


ENV DIRPATH /home/${DOCKER_USER_}
WORKDIR $DIRPATH

RUN useradd ${DOCKER_USER_} \
    && chown -R ${DOCKER_USER_} ${DIRPATH}

USER ${DOCKER_USER_}

COPY --from=textlint /usr/local/bin/ /usr/local/bin/
COPY --from=textlint /usr/local/lib/ /usr/local/lib/
COPY --from=textlint /textlint-rule-ja-custom-ng-word/ /textlint-rule-ja-custom-ng-word/

COPY ./internal/media/ ${DIRPATH}/internal/media/
COPY ./internal/scripts/ ${DIRPATH}/internal/scripts/
COPY ./internal/style/ ${DIRPATH}/internal/style/

COPY .textlintrc ${DIRPATH}/

# ENV PATH $PATH:${DIRPATH}/node_modules/textlint/bin