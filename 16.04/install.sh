#!/bin/bash
set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/../common/helpers.sh
source ${CURRENT_DIR}/../common/ansi.sh
source ${CURRENT_DIR}/../common/spinner.sh

[ $(id -u) != "0" ] && { ansi -n --bg-red "请用 root 账户执行本脚本"; exit 1; }

MYSQL_ROOT_PASSWORD=`random_string`
LOG_PATH=/var/log/laravel-ubuntu-init.log
WWW_USER="www-data"
WWW_USER_GROUP="www-data"

function init_system {
    export LC_ALL="en_US.UTF-8"
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    locale-gen en_US.UTF-8

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    apt-get update
    apt-get install -y software-properties-common
}

function init_repositories {
    add-apt-repository -y ppa:ondrej/php
    add-apt-repository -y ppa:nginx/stable
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
    curl -sL https://deb.nodesource.com/setup_8.x | bash -
    sed -i "s/https:\/\/deb.nodesource.com\/node_8.x/https:\/\/mirrors.tuna.tsinghua.edu.cn\/nodesource\/deb_8.x/g" /etc/apt/sources.list.d/nodesource.list
    grep -rl ppa.launchpad.net /etc/apt/sources.list.d/ | xargs sed -i 's/ppa.launchpad.net/launchpad.proxy.ustclug.org/g'
    apt-get update
}

function install_basic_softwares {
    apt-get install -y curl git build-essential unzip supervisor
}

function install_node_yarn {
    apt-get install -y nodejs yarn
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && yarn config set registry https://registry.npm.taobao.org'
}

function install_php {
    apt-get install -y php7.2-bcmath php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-pgsql php7.2-readline php7.2-xml php7.2-zip php7.2-sqlite3
}

function install_nmr {
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"
    apt-get install -y nginx mysql-server redis-server
    chown -R ${WWW_USER}.${WWW_USER_GROUP} /var/www/
}

function install_composer {
    wget https://dl.laravel-china.org/composer.phar -O /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && composer config -g repo.packagist composer https://packagist.laravel-china.org'
}

spinner_function init_system "===> 正在初始化系统" ${LOG_PATH}
spinner_function init_repositories "===> 正在初始化软件源" ${LOG_PATH}
spinner_function install_basic_softwares "===> 正在安装基础软件" ${LOG_PATH}
spinner_function install_php "===> 正在安装 PHP" ${LOG_PATH}
spinner_function install_nmr "===> 正在安装 Mysql / Nginx / Redis" ${LOG_PATH}
spinner_function install_node_yarn "===> 正在安装 Nodejs / Yarn" ${LOG_PATH}
spinner_function install_composer "===> 正在安装 Composer" ${LOG_PATH}

ansi --green -n "安装完毕"
ansi --green "Mysql root 密码："; ansi -n --bg-red ${MYSQL_ROOT_PASSWORD}
