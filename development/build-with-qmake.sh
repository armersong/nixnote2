#!/bin/bash
# here we expected that the particular version of qmake, you want to use  is found on PATH
# so if you want to use something different then default - make sure you adjust path before calling this script

BUILD_TYPE=${1}
CLEAN=${2}
TIDY_DIR=${3}
CDIR=`pwd`

function error_exit {
    echo "***********error_exit***********"
    echo "***********" 1>&2
    echo "*********** Failed: $1" 1>&2
    echo "***********" 1>&2
    cd ${CDIR}
    exit 1
}

if [ ! -f src/main.cpp ]; then
  echo "You seem to be in wrong directory. script MUST be run from the project directory."
  exit 1
fi

if [ -z "${BUILD_TYPE}" ]; then
    BUILD_TYPE=debug
fi
BUILD_DIR=qmake-build-${BUILD_TYPE}

if [ "${CLEAN}" == "clean" ]; then
  echo "Clean build: ${BUILD_DIR}"
  if [ -d "${BUILD_DIR}" ]; then
    rm -rf ${BUILD_DIR}
  fi
fi

if [ -z "${TIDY_DIR}" ]; then
   # system default
   TIDY_DIR=/usr
fi
TIDY_LIB_DIR=${TIDY_DIR}/lib
if [ ! -d "${TIDY_DIR}" ] || [ ! -d "${TIDY_LIB_DIR}" ]; then
   echo "TIDY_DIR or TIDY_DIR/lib is not a directory"
   exit 1
fi
echo "libtidy is expected in: ${TIDY_LIB_DIR}"





if [ ! -d "${BUILD_DIR}" ]; then
  mkdir ${BUILD_DIR}
fi

echo "${BUILD_DIR}">_build_dir_.txt

APPDIR=appdir
if [ -d "${APPDIR}" ]; then
  rm -rf ${APPDIR}
  rm *.AppImage 2>/dev/null
fi


QMAKE_BINARY=qmake


if [ "${TIDY_DIR}" == "/usr" ] ; then
  # at least on ubuntu pkgconfig for "libtidy-dev" is not installed - so we provide default
  # there could be better option
  # check: env PKG_CONFIG_PATH=./development/pkgconfig pkg-config --libs --cflags tidy
  CDIR=`pwd`
  echo export PKG_CONFIG_PATH=${CDIR}/development/pkgconfig
  export PKG_CONFIG_PATH=${CDIR}/development/pkgconfig
elif [ -d ${TIDY_LIB_DIR}/pkgconfig ] ; then
  echo export PKG_CONFIG_PATH=${TIDY_LIB_DIR}/pkgconfig
  export PKG_CONFIG_PATH=${TIDY_LIB_DIR}/pkgconfig
fi


echo ${QMAKE_BINARY} CONFIG+=${BUILD_TYPE} PREFIX=appdir/usr QMAKE_RPATHDIR+=${TIDY_LIB_DIR} || error_exit "qmake"
${QMAKE_BINARY} CONFIG+=${BUILD_TYPE} PREFIX=appdir/usr QMAKE_RPATHDIR+=${TIDY_LIB_DIR} || error_exit "qmake"

make -j8 || error_exit "make"
make install || error_exit "make install"
