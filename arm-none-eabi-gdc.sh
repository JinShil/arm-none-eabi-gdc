#!/bin/bash

# Copyright © 2019 Michael V. Franklin
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

TARGET=arm-none-eabi
PREFIX=`pwd`/result
GDC_BRANCH=master

#===================================================================
# BINUTILS
#===================================================================
BINUTILS_NAME=binutils-2.32
BINUTILS_SOURCE_ARCHIVE=$BINUTILS_NAME.tar.bz2

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
BINUTILS_BUILD_DIR=binutils-build
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
GCC_NAME=gcc
rm -rf $GCC_NAME              # remove any existing folders
mkdir $GCC_NAME
git clone https://github.com/D-Programming-GDC/gcc.git $GCC_NAME
cd $GCC_NAME
git checkout trunk            # checkout the appropriate branch

# Patch GCC
#-------------------------------------------------------------------
mkdir -p gcc/config/arm
cp ../t-arm-elf gcc/config/arm/

# Create GCC build directory
#-------------------------------------------------------------------
GCC_BUILD_DIR=gcc-build
rm -rf $GCC_BUILD_DIR  # remove existing folder
mkdir $GCC_BUILD_DIR

# Configure and build GCC with support for D
#-------------------------------------------------------------------
cd $GCC_BUILD_DIR
../configure --target=$TARGET --prefix=$PREFIX \
  --enable-languages=d      \
  --enable-checking=release \
  --disable-bootstrap       \
  --disable-libssp          \
  --disable-libgomp         \
  --disable-libmudflap      \
  --disable-libphobos       \
  --disable-decimal-float   \
  --disable-libffi          \
  --disable-libquadmath     \
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


