FROM node:18.11.0-slim AS node
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
    npm=6.14.4+ds-1ubuntu2 \
    && apt-get -y clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g \
    textlint@v12.2.3 \
    textlint-rule-preset-ja-technical-writing@7.0.0 \
    textlint-rule-preset-ja-spacing@2.2.0 \
    textlint-rule-preset-jtf-style@2.3.13 \
    textlint-rule-preset-ja-engineering-paper@1.0.4 \
    textlint-plugin-latex2e@1.2.0 \
    @textlint/ast-node-types@12.2.2 \
    && npm cache clean --force

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

COPY ./internal/media/semi-rule.yml ${DIRPATH}/node_modules/prh/prh-rules/media/
COPY ./internal/media/WEB+DB_PRESS.yml ${DIRPATH}/node_modules/prh/prh-rules/media/

COPY .textlintrc ${DIRPATH}/

# ENV PATH $PATH:${DIRPATH}/node_modules/textlint/bin

