#!/usr/bin/env bash

shopt -s extglob

BUILDERDIR="$(dirname "$0")"

# variables needed later.
start_dir=`pwd`
nginx_install_dir="$HOME/nginx"
graphite_install_dir="$HOME/graphite"
stage_dir="$start_dir/tmp"
nginx_stage_dir="$stage_dir/stage"
nginx_download_url="http://nginx.org/download/nginx-1.2.1.tar.gz"  #TODO configurable?
statsite_install_dir="$HOME/statsite"
carbon_version=origin/0.9.x
graphite_version=origin/0.9.x


# functions
msg() {
    echo -e "\033[1;32m-->\033[0m $0:" $*
}

die() {
    msg $*
    exit 1
}

move_to_approot() {
    [ -n "$SERVICE_APPROOT" ] && cd $SERVICE_APPROOT
}

clean_nginx() {
    if [ -d $nginx_install_dir ] ; then
        msg "cleaning up ($nginx_install_dir)"
        rm -rf $nginx_install_dir
    fi
}

clean_statsite() {
    if [ -d $statsite_install_dir ] ; then
        msg "cleaning up ($statsite_install_dir)"
        rm -rf $statsite_install_dir
    fi
}

clean_graphite() {
    if [ -d $graphite_install_dir ] ; then
        msg "cleaning up ($graphite_install_dir)"
        rm -rf $graphite_install_dir
    fi
}

setup() {
    msg "making directory: $nginx_stage_dir"
    mkdir -p $nginx_stage_dir
}

install_nginx() {
    local nginx_url=$nginx_download_url

    msg "installing nginx into: $nginx_install_dir"

    # install nginx
    if [ ! -d $nginx_install_dir ] ; then
        mkdir -p $nginx_install_dir

        msg "downloading nginx from ($nginx_url) and untarring into ($nginx_stage_dir) "
        wget -O - $nginx_url | tar -C $nginx_stage_dir --strip-components=1 -zxf -
        [ $? -eq 0 ] || die "can't fetch nginx"

        msg "successfully downloaded and untarred nginx"

        cd $nginx_stage_dir

        msg "compiling and installing nginx"
        export CFLAGS="-O3 -pipe"
           ./configure   \
            --prefix=$nginx_install_dir \
            --with-http_gzip_static_module \
            --with-http_realip_module \
            --with-http_stub_status_module \
            --with-http_ssl_module && make && make install
        [ $? -eq 0 ] || die "nginx install failed"

        rm $nginx_install_dir/conf/*.default

        cd $start_dir

        msg "finished installing nginx"
    else
        msg "nginx already installed, skipping this step"
    fi

    msg "installing nginx config"
    mv $start_dir/conf/nginx.conf $nginx_install_dir/conf/
    touch $nginx_install_dir/conf/basic_auth.conf
}

build_profile(){
    cat > $start_dir/profile << EOF
export PATH="$HOME/bin:$graphite_install_dir/bin:$statsite_install_dir:$nginx_install_dir/sbin:$PATH"
export PYTHONPATH="$graphite_install_dir:$PYTHONPATH"
export GRAPHITE_STORAGE_DIR="/home/dotcloud/data"
EOF

    msg "moving $start_dir/profile to ~/"
    mv $start_dir/profile ~/
    rm -rf ~/bin
    mv $start_dir/bin ~/
}

install_python_deps() {
    msg "setting up virtualenv"
    virtualenv $graphite_install_dir
    source $graphite_install_dir/bin/activate

    msg "installing python deps with pip"
    pip install -r requirements.txt

    msg "done install python deps"
}

install_statsite() {
    if [ ! -d $statsite_install_dir ] ; then
        msg "cloning statsite"
        git clone git://github.com/armon/statsite.git $statsite_install_dir

        cd $statsite_install_dir

        msg "building statsite"
        scons

        cd $start_dir

        msg "finished installing statsite"
    else
        msg "statsite already installed, skipping this step"
    fi

    msg "copying config"
    mv $start_dir/conf/statsite.conf $statsite_install_dir
}

install_graphite() {
    if [ ! -d "$graphite_install_dir/webapp" ] ; then
        cd $stage_dir

        msg "checking out carbon $carbon_version"
        git clone git://github.com/graphite-project/carbon.git
        cd carbon
        git reset --hard $carbon_version

        msg "installing carbon"
        python setup.py install --prefix=$graphite_install_dir --install-lib=$graphite_install_dir

        cd $stage_dir

        msg "checking out graphite-web $graphite_version"
        git clone git://github.com/graphite-project/graphite-web.git
        cd graphite-web
        git reset --hard $graphite_version

        msg "installing graphite-web"
        python setup.py install --prefix=$graphite_install_dir --install-lib=$graphite_install_dir

        if [ ! -d "$HOME/data" ] ; then
          msg "moving data directories into place"
          mv $graphite_install_dir/storage $HOME/data
        fi

        msg "graphite install complete."
    else
        msg "graphite already installed, skipping this step"
    fi

    msg "moving config files into place"
    mv $start_dir/conf/graphite_local_settings.py $graphite_install_dir/graphite/local_settings.py
    mv $start_dir/conf/* $graphite_install_dir/conf
}

cleanup() {
    msg "cleaning up $stage_dir"
    rm -rf $stage_dir
}

# lets get started.

msg "Step 0: getting ready for build::"
move_to_approot
setup

# If you want to rebuild nginx from scratch and remove a previously good compile
# uncomment this. Don't do this everytime, or else each build will be slow.
# msg "Step 1A: cleaup old nginx build::"
#clean_nginx
#clean_statsite
#clean_graphite

msg "Step 1: install nginx::"
install_nginx

msg "Step 2: build profile::"
build_profile

msg "Step 4: install python dependencies::"
install_python_deps

msg "Step 5: install statsite::"
install_statsite

msg "Step 6: install graphite::"
install_graphite

msg "Step 7: cleanup::"
cleanup

msg "all done..."
