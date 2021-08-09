#!/usr/bin/env bash

set -e

function install_pkg(){
    sudo apt install jq qemu binfmt-support qemu-user-static -y
}

function check_version(){
    latest_version=$(curl -s "https://api.github.com/repos/caddyserver/caddy/releases/latest" | jq -r .tag_name)
    latest_build_version=$(cat version)

    if [ "${latest_version}" != "${latest_build_version}" ]; then
        echo ${latest_version} > version
        return 1
    else
        return 0
    fi
}


function init_earthly(){
     sudo wget -q -O /usr/local/bin/earthly $(curl -sL https://api.github.com/repos/earthly/earthly/releases/latest \
         | jq -r '.assets[].browser_download_url' | grep earthly-linux-amd64)
     sudo chmod +x /usr/local/bin/earthly
}

function build(){
    earthly -P --build-arg VERSION=$(cat version) --push +all
    git add version
    git commit -m "$(cat version): GitHub Action Auto Update(`date +'%Y-%m-%d %H:%M:%S'`)"
    git push https://mritd:${COMMIT_TOKEN}@github.com/mritd/autobuild.git
}

install_pkg
check_version

if [ "$?" == 1 ]; then
    init_earthly
    build
else
    echo "\033[1;32mNo update found.\033[0m"
fi
