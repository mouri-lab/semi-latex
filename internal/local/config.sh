#!/bin/bash
cd $(dirname $(readlink -f $0))/../../
readonly CONTAINER_NAME=latex-container
readonly STYLE_DIR=$(readlink -f internal/container/style)
readonly SCRIPTS_DIR=$(readlink -f internal/local)
readonly DOCKER_HOME_DIR=/home/guest
readonly ARCH=$(uname -m)
cd -