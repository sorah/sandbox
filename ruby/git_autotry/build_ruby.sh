#!/bin/bash -e
set -x

autoconf

[ ! -d build ] && mkdir build
cd build

../configure --prefix=`pwd`/local --with-readline-dir=$(brew --prefix readline) \
  --with-openssl-dir=$(brew --prefix openssl) \
  --enable-shared --enable-pthread --disable-install-doc --disable-install-capi --with-arch=x86_64 --with-gcc=clang debugflags="-gdwarf-2 -g3" optflags="-O0"

make -j5 main
make install-nodoc

PATH=`pwd`/local:$PATH

gem pristine --all --extensions
gem install --no-rdoc --no-ri bundler
