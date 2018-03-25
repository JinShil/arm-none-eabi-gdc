#!/bin/bash

# Copyright © 2015 Michael V. Franklin
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this file. If not, see <http://www.gnu.org/licenses/>.

# References
#------------------------------------------------------------------
# gcc.gnu.org/install/configure.html
# http://wiki.dlang.org/GDC/Cross_Compiler/Generic
# http://wiki.dlang.org/Bare_Metal_ARM_Cortex-M_GDC_Cross_Compiler

# stop if an error is encountered
set -e

export TARGET=arm-none-eabi
export PREFIX=`pwd`/result
export GDC_VERSION=7
export GCC_VERSION=$GDC_VERSION.1.0

#===================================================================
# BINUTILS
#===================================================================
export BINUTILS_NAME=binutils-2.28
export BINUTILS_SOURCE_ARCHIVE=$BINUTILS_NAME.tar.bz2

# remove any existng files or folders
rm -f $BINUTILS_SOURCE_ARCHIVE
rm -rf $BINUTILS_NAME

# Get and Extract binutils
#-------------------------------------------------------------------
wget http://ftpmirror.gnu.org/binutils/$BINUTILS_SOURCE_ARCHIVE
tar xjfv $BINUTILS_SOURCE_ARCHIVE
rm -rf $BINUTILS_SOURCE_ARCHIVE  # don't need archive file anymore

# Create binutils build directory
#-------------------------------------------------------------------
export BINUTILS_BUILD_DIR=binutils-build
rm -rf $BINUTILS_BUILD_DIR  # remove any existing folders
mkdir $BINUTILS_BUILD_DIR

# Configure and build binutils
#-------------------------------------------------------------------
cd $BINUTILS_BUILD_DIR
../$BINUTILS_NAME/configure \
  --target=$TARGET   \
  --prefix=$PREFIX   \
  --disable-nls      \
  --with-gnu-as      \
  --with-gnu-ld      \
  --disable-libssp

make -j4 all
make install
cd ..

# Clean up
rm -rf $BINUTILS_BUILD_DIR
rm -rf $BINUTILS_NAME

#===================================================================
# GDC and GCC
#===================================================================
export GDC_NAME=gdc
rm -rf $GDC_NAME              # remove any existing folders
mkdir gdc
git clone https://github.com/D-Programming-GDC/GDC.git $GDC_NAME
cd $GDC_NAME
git checkout gdc-$GDC_VERSION # checkout the appropriate branch
cd ..

# Delete existing GCC source archive and download a new one
#-------------------------------------------------------------------
export GCC_MIRROR=http://ftpmirror.gnu.org/gcc
export GCC_NAME=gcc-$GCC_VERSION
export GCC_SOURCE_ARCHIVE=$GCC_NAME.tar.bz2

# Remove any existing files or folders
rm -f $GCC_SOURCE_ARCHIVE
rm -rf $GCC_NAME

# Extract GCC
#-------------------------------------------------------------------
wget $GCC_MIRROR/$GCC_NAME/$GCC_SOURCE_ARCHIVE
tar xjfv $GCC_SOURCE_ARCHIVE
rm -rf $GCC_SOURCE_ARCHIVE    # don't need archive file anymore

# Add GDC to GCC
#-------------------------------------------------------------------
cd gdc
./setup-gcc.sh ../$GCC_NAME
cd ..

# Patch GDC
#-------------------------------------------------------------------
# cd $GCC_NAME
# cp ../issue_108.patch .
# patch -p1 -i issue_108.patch

# cp ../issue_114.patch .
# patch -p1 -i issue_114.patch

# cp ../issue_114-2.patch .
# patch -p1 -i issue_114-2.patch
# cd ..

# Create GDC build directory
#-------------------------------------------------------------------
export GCC_BUILD_DIR=gcc-build
rm -rf $GCC_BUILD_DIR  # remove existing folder
mkdir $GCC_BUILD_DIR

# Patch GCC
#-------------------------------------------------------------------
cp t-arm-elf $GCC_NAME/gcc/config/arm/

# Configure and build GDC
#-------------------------------------------------------------------
cd $GCC_BUILD_DIR
../$GCC_NAME/configure --target=$TARGET --prefix=$PREFIX \
  --enable-languages=d      \
  --enable-checking=release \
  --disable-bootstrap       \
  --disable-libssp          \
  --disable-libgomp         \
  --disable-libmudflap      \
  --disable-libphobos       \
  --disable-decimal-float   \
  --disable-libffi          \
  --disable-libmudflap      \
  --disable-libquadmath     \
  --disable-libssp          \
  --disable-libstdcxx       \
  --disable-libstdcxx-pch   \
  --disable-nls             \
  --disable-shared          \
  --disable-threads         \
  --disable-tls             \
  --with-gnu-as             \
  --with-gnu-ld             \
  --with-mode=thumb         \
  --without-headers

make -j4 all-gcc
make -j4 all-target-libgcc

make install-gcc
make install-target-libgcc
cd ..

# Clean up
rm -rf $GCC_BUILD_DIR
rm -rf $GCC_NAME
rm -rf $GDC_NAME


