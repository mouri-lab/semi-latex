#!/bin/bash

readonly CONTAINER_NAME=latex-container
readonly STYLE_DIR=internal/container/style
readonly SCRIPTS_DIR=internal/local
readonly DOCKER_HOME_DIR=/home/guest
readonly ARCH=$(uname -m)