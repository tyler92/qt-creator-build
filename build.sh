#!/bin/bash

#set -e
trap 'echo EXIT && exit' err
set -x

QT_VERSION=6.5.2
QT_CREATOR_VERSION=12.0.1
LLVM_VERSION=llvmorg-17.0.6
CLAZY_VERSION=1.11
JOBS=10

INSTALL_PREFIX=/opt/qt-creator/$QT_CREATOR_VERSION
WORKDIR=/tmp/workdir

mkdir -p $WORKDIR
cd $WORKDIR

# CMake checkout and build
git clone https://gitlab.kitware.com/cmake/cmake.git --depth 1
cd cmake
./bootstrap && make -j$JOBS && make install && make clean

# LLVM download and extract
echo "Build LLVM"
cd $WORKDIR
git clone https://github.com/llvm/llvm-project.git -b $LLVM_VERSION --depth 1
mkdir -p llvm-project/build && cd llvm-project/build
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
      ../llvm
make -j$JOBS && make install && make clean
export PATH=$PATH:$INSTALL_PREFIX/bin

#echo "Build clazy"
#cd $WORKDIR
#git clone https://github.com/KDE/clazy.git -b $CLAZY_VERSION
#cd clazy && git apply /root/clazy.patch && cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX . && make -j$JOBS && make install

# Download and build Qt
echo "Checkout Qt sources"
cd $WORKDIR
git clone https://code.qt.io/qt/qt5.git -b $QT_VERSION --depth 1
cd qt5 && ./init-repository --module-subset=default,-qtwebengine

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
cmake --build . --parallel

echo "Installing Qt ..."
cmake --build . --target install
cmake --build . --target clean

# Download and build Qt-Creator
echo "Checkout Qt-Creator sources"
cd $WORKDIR
git clone https://code.qt.io/qt-creator/qt-creator.git -b v$QT_CREATOR_VERSION --depth 1

cd qt-creator
git submodule update --init --recursive

mkdir -p ../build-creator
cd ../build-creator

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_INSTALL_RPATH=$INSTALL_PREFIX/lib \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=On \
    -DPYTHON_EXECUTABLE=`which python3` ../qt-creator

echo "Building Qt-Creator ..."
make -j$JOBS

echo "Installing Qt-Creator ..."
cmake --build . --target install
cmake --build . --target clean

# Collect artifacts
mkdir -p /root/install
cd /root/install
tar -zcf qt-creator-$QT_CREATOR_VERSION.tar.gz $INSTALL_PREFIX

echo "Done"
