#!/bin/bash

set -e
set -x

QT_VERSION=6.4.2
QT_CREATOR_VERSION=9.0.2
LLVM_VERSION=release/15.x
CLAZY_VERSION=1.11

INSTALL_PREFIX=/opt/qt-creator/$QT_CREATOR_VERSION
WORKDIR=/tmp/workdir

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

mkdir -p $WORKDIR
cd $WORKDIR

# CMake checkout and build
git clone https://gitlab.kitware.com/cmake/cmake.git --depth 1
cd cmake
./bootstrap && make -j7 && make install && make clean

# LLVM download and extract
echo "Build LLVM"
cd $WORKDIR
git clone https://github.com/llvm/llvm-project.git -b $LLVM_VERSION --depth 1
mkdir llvm-project/build && cd llvm-project/build
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
      ../llvm
make -j7 && make install && make clean
export PATH=$PATH:$INSTALL_PREFIX/bin

echo "Build clazy"
cd $WORKDIR
git clone https://github.com/KDE/clazy.git -b $CLAZY_VERSION
cd clazy && cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX . && make -j4 && make install

# Download and build Qt
echo "Checkout Qt sources"
cd $WORKDIR
git clone https://code.qt.io/qt/qt5.git -b $QT_VERSION --depth 1
cd qt5 && ./init-repository

echo "Configure Qt"
cd $WORKDIR && mkdir -p build && cd build
../qt5/configure \
    -prefix $INSTALL_PREFIX \
    -opensource \
    -confirm-license \
    -skip qtwebengine -skip qt3d -skip qtspeech -skip qtquick3d -skip qtquick3dphysics -skip qtdoc \
    -nomake examples -nomake tests \
    -silent

echo "Building Qt ..."
make -j6

echo "Installing Qt ..."
make install
make clean

# Download and build Qt-Creator
echo "Checkout Qt-Creator sources"
cd $WORKDIR
git clone https://code.qt.io/qt-creator/qt-creator.git -b v$QT_CREATOR_VERSION --depth 1

cd qt-creator
git submodule update --init --recursive

mkdir ../build-creator
cd ../build-creator

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_INSTALL_RPATH=$INSTALL_PREFIX/lib \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=On \
    -DPYTHON_EXECUTABLE=`which python3` ../qt-creator

#read -p "Press enter to continue"

echo "Building Qt-Creator ..."
make -j6

echo "Installing Qt-Creator ..."
make install

# Collect artifacts
mkdir -p /root/install
cd /root/install
tar -zcf qt-creator-$QT_CREATOR_VERSION.tar.gz $INSTALL_PREFIX

echo "Done"
