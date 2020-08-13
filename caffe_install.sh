# This script installs (or at least, attempts to install) Caffe in CPU mode
# with Python bindings without root permission. In doing so, it installs the
# following dependencies:
#
# * protobuf
# * cmake
# * gflags
# * glog
# * opencv
# * hdf5
# * python2
# * pip
# * libpng (recent version required for freetype)
# * automake (recent version required for freetype)
# * freetype (required for scikit-image)
# * various python modules
#     - numpy
#     - scipy
#     - scikit-image
#     - protobuf
#     - yaml
# * boost
# * lmdb
# * libtool
# * snappy
# * leveldb
# * openblas

LOCAL_INSTALL_DIR="${HOME}/local"
SCRATCH_DIR="${HOME}/scratch_for_setup"
CAFFE_INSTALL_DIR="${HOME}/caffe"

# Note that changing these versions may not work - it's a little fragile and
# depends on the URLs for these utilities to have the same template across
# versions (e.g. http://example.com/tool/tool_v${version_number}). The URLs
# work with the versions listed as of the last committed version, but should
# be tested before updating and committing.
PROTOBUF_VERSION="2.6.1"
GFLAGS_VERSION="2.1.2"
GLOG_VERSION="0.3.4"
OPENCV_VERSION="2.4.11"
LMDB_VERSION="0.87"
PYTHON_VERSION="2.7.10" # Must be python2.*
LIBPNG_VERSION="1.6.18"
FREETYPE_VERSION="2.6.1"
LIBTOOL_VERSION="2.4.6"
AUTOMAKE_VERSION="1.15"
LEVELDB_VERSION="1.18"
OPENBLAS_VERSION="0.2.14"

# Hardcoded versions - these cannot be changed here.
# TODO: Allow changing the below values.
# BOOST_VERSION="1.59.0"
# HDF5_VERSION="1.8.15-patch1"
# CMAKE_VERSION="3.2.3"

# E.g. 2.7.10 -> python2.7
PYTHON_SHORT_VERSION="$(echo $PYTHON_VERSION | sed -e 's/\([0-9]*\.[0-9]*\)\(\..*\)\?/\1/g')"
PYTHON_BINARY="python${PYTHON_SHORT_VERSION}"

# Exit on error.
set -e

# Taken from
# https://github.com/achalddave/dotfiles/blob/master/misc/sudo-less-servers/install_utilities.sh
# Usage: untar_to_dir <tar_file> <output_directory>
# Untars to a specified directory, instead of using the "root" directory
# specified in the tar file. Useful for cd'ing.
untar_to_dir() {
    if [[ "$#" -ne 2 ]] ; then
        echo "Improper number of arguments to untar_to_dir"
        exit
    fi

    TAR_FILE="${1}"
    OUTPUT="${2}"
    mkdir -p "${OUTPUT}"

    tar xzvf "${TAR_FILE}" -C "${OUTPUT}" --strip-components=1
}

# Usage: scratch_init <utility_name>
scratch_init() {
    if [[ "$#" -ne 1 ]] ; then
        echo "Improper number of arguments to scratch_init"
        exit
    fi

    cd "${SCRATCH_DIR}"
    mkdir -p "$1"
    cd "$1"
}

install_protobufs() {
    scratch_init protobuf

    wget "https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz"
    untar_to_dir "protobuf-${PROTOBUF_VERSION}.tar.gz" protobuf-${PROTOBUF_VERSION}
    cd protobuf-${PROTOBUF_VERSION}

    ./configure --prefix="${LOCAL_INSTALL_DIR}/protobuf-${PROTOBUF_VERSION}"
    make -j4
    make install
}

install_cmake() {
    scratch_init cmake

    # Cmake has pre-built binaries ready, so we will just untar it in
    # ${LOCAL_INSTALL_DIR}.
    wget "https://cmake.org/files/v3.2/cmake-3.2.3-Linux-x86_64.tar.gz"
    untar_to_dir "cmake-3.2.3-Linux-x86_64.tar.gz"
    cd ${LOCAL_INSTALL_DIR}

    echo "You will need to add the following line to your .zshrc/.bashrc:"
    echo 'export CMAKE_ROOT="'${LOCAL_INSTALL_DIR}'/share/cmake-3.2"'
}

install_gflags() {
    scratch_init gflags

    wget "https://github.com/gflags/gflags/archive/v${GFLAGS_VERSION}.tar.gz"
    untar_to_dir "v${GFLAGS_VERSION}.tar.gz" "v${GFLAGS_VERSION}"
    cd "v${GFLAGS_VERSION}"

    mkdir build
    cd build

    cmake -D CMAKE_INSTALL_PREFIX="${LOCAL_INSTALL_DIR}" -D CMAKE_POSITION_INDEPENDENT_CODE=ON ..
    make
    make install
}

install_glog() {
    scratch_init glog

    wget "https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz"
    untar_to_dir "v${GLOG_VERSION}.tar.gz" "v${GLOG_VERSION}"
    cd "v${GLOG_VERSION}"

    ./configure --prefix="${LOCAL_INSTALL_DIR}/glog-${GLOG_VERSION}"
    make
    make install
}

install_opencv() {
    scratch_init opencv

    wget "https://github.com/Itseez/opencv/archive/${OPENCV_VERSION}.tar.gz" -O "opencv-${OPENCV_VERSION}.tar.gz"
    untar_to_dir "opencv-${OPENCV_VERSION}.tar.gz" "opencv-${OPENCV_VERSION}"
    cd "opencv-${OPENCV_VERSION}"

    mkdir release
    cd release
    cmake -D BUILD_ZLIB=ON -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX="${LOCAL_INSTALL_DIR}" -D BUILD_PYTHON_SUPPORT=ON -D WITH_GTK=OFF ..

    # Update ${SCRATCH_DIR}/opencv-2.4.11/release/modules/features2d/CMakeFiles/opencv_features2d.dir/build.make
    # cd ${SCRATCH_DIR}/opencv/opencv-2.4.11/release/modules/features2d && /usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -o CMakeFiles/opencv_features2d.dir/src/freak.cpp.o -c ${SCRATCH_DIR}/opencv/opencv-2.4.11/modules/features2d/src/freak.cpp
    # to
    # cd ${SCRATCH_DIR}/opencv/opencv-2.4.11/release/modules/features2d && /usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -O0 -o CMakeFiles/opencv_features2d.dir/src/freak.cpp.o -c ${SCRATCH_DIR}/opencv/opencv-2.4.11/modules/features2d/src/freak.cpp
    # (Add -O0 after CXX_FLAGS)
    # This is necessary due to http://stackoverflow.com/a/14619427/1291812
    sed -i'' -e \
        's:'${SCRATCH_DIR}'/opencv/opencv-2.4.11/release/modules/features2d && /usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -o CMakeFiles/opencv_features2d.dir/src/freak.cpp.o -c '${SCRATCH_DIR}'/opencv/opencv-2.4.11/modules/features2d/src/freak.cpp:'${SCRATCH_DIR}'/opencv/opencv-2.4.11/release/modules/features2d && /usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -O0 -o CMakeFiles/opencv_features2d.dir/src/freak.cpp.o -c '${SCRATCH_DIR}'/opencv/opencv-2.4.11/modules/features2d/src/freak.cpp"' \
        "${SCRATCH_DIR}/opencv-2.4.11/release/modules/features2d/CMakeFiles/opencv_features2d.dir/build.make"

    make -j16
    make install
}

install_hdf5() {
    scratch_init hdf5

    wget "http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.15-patch1.tar.gz"
    untar_to_dir "hdf5-1.8.15-patch1.tar.gz" "hdf5-1.8.15"
    cd hdf5-1.8.15

    ./configure --prefix="${LOCAL_INSTALL_DIR}/hdf5-1.8.15"
    make -j4
    make install
}

install_libpng() {
    scratch_init libpng

    wget "http://downloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz"
    untar_to_dir "libpng-${LIBPNG_VERSION}.tar.gz" "libpng-${LIBPNG_VERSION}"
    cd "libpng-${LIBPNG_VERSION}"

    LDFLAGS="-L${LOCAL_INSTALL_DIR}/lib" ./configure --prefix="${LOCAL_INSTALL_DIR}/libpng-${LIBPNG_VERSION}"
    make -j4
    make install
}

install_automake() {
    scratch_init automake

    wget "http://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VERSION}.tar.gz"
    untar_to_dir "automake-${AUTOMAKE_VERSION}.tar.gz" "automake-${AUTOMAKE_VERSION}"
    cd "automake-${AUTOMAKE_VERSION}"

    ./configure --prefix="${LOCAL_INSTALL_DIR}/automake-${AUTOMAKE_VERSION}"
    make -j4
    make install
}

install_freetype() {
    scratch_init freetype

    wget "http://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz"
    untar_to_dir "freetype-${FREETYPE_VERSION}.tar.gz" "freetype-${FREETYPE_VERSION}"
    cd "freetype-${FREETYPE_VERSION}"

    ./autogen.sh
    ./configure --prefix="${LOCAL_INSTALL_DIR}/freetype-${FREETYPE_VERSION}"
    make
    make install
}

# Taken from
# https://github.com/achalddave/dotfiles/blob/master/misc/sudo-less-servers/install_utilities.sh
install_python2() {
    scratch_init python2

    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    untar_to_dir "Python-${PYTHON_VERSION}.tgz" "python-${PYTHON_VERSION}"

    cd "python-${PYTHON_VERSION}"
    ./configure --prefix="${LOCAL_INSTALL_DIR}/python-${PYTHON_VERSION}" --enable-shared
    make -j4
    make altinstall
}

# Taken from
# https://github.com/achalddave/dotfiles/blob/master/misc/sudo-less-servers/install_utilities.sh
install_pip() {
    scratch_init pip2

    wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
    ${PYTHON_BINARY} get-pip.py
}

install_python_modules() {
    ${PYTHON_BINARY} -m pip install numpy
    ${PYTHON_BINARY} -m pip install scipy
    ${PYTHON_BINARY} -m pip install scikit-image
    ${PYTHON_BINARY} -m pip install protobuf
    ${PYTHON_BINARY} -m pip install pyyaml
}

# TODO: This does not install the python bindings, it seems... That is,
# import boost
# does not work in python.
install_boost() {
    scratch_init boost

    wget "http://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz/download" -O "boost_1_59_0.tar.gz"
    untar_to_dir "boost_1_59_0.tar.gz" "boost_1_59_0"

    cd boost_1_59_0
    ./bootstrap.sh --prefix="${LOCAL_INSTALL_DIR}/boost-1.59.0" --with-python="${LOCAL_INSTALL_DIR}/python-${PYTHON_VERSION}/bin/python${PYTHON_SHORT_VERSION}"
    ./b2 install
}

install_lmdb() {
    scratch_init lmdb

    wget "https://github.com/dw/py-lmdb/archive/py-lmdb_${LMDB_VERSION}.tar.gz"
    untar_to_dir "py-lmdb_${LMDB_VERSION}.tar.gz" "py-lmdb_${LMDB_VERSION}"
    cd "py-lmdb_${LMDB_VERSION}"
    ${PYTHON_BINARY} setup.py install

    # Contains the actual LMDB sources?
    scratch_init openldap
    wget "ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.42.tgz"
    untar_to_dir "openldap-2.4.42.tgz" openldap-2.4.42
    cd openldap-2.4.42/libraries/lmdb
    make -j4
    sed -i'' -e 's:\(prefix.*=\).*:\1'${LOCAL_INSTALL_DIR}':g' Makefile
    make install
}

install_libtool() {
    scratch_init libtool

    wget "http://ftpmirror.gnu.org/libtool/libtool-${LIBTOOL_VERSION}.tar.gz"
    untar_to_dir "libtool-${LIBTOOL_VERSION}.tar.gz" "libtool-${LIBTOOL_VERSION}"
    cd libtool-${LIBTOOL_VERSION}

    ./configure --prefix="${LOCAL_INSTALL_DIR}/libtool-${LIBTOOL_VERSION}"
    make -j4
    make install
}

install_snappy() {
    scratch_init snappy

    wget "https://github.com/google/snappy/tarball/master" -O snappy.tar.gz
    untar_to_dir "snappy.tar.gz" "libsnappy"
    cd "libsnappy"

    ./autogen.sh
    echo "AC_PROG_LIBTOOL" >>config.ac
    ./configure --prefix="${LOCAL_INSTALL_DIR}/snappy"
    make
    make install
    # The default autogen.sh does not handle compatibility well... This one,
    # from the following PR: https://github.com/google/snappy/pull/4 is
    # preferable.
    #wget https://raw.githubusercontent.com/juanmaneo/snappy/49262984cddf3985fba7d1ceca6b14986f6dbef0/autogen.sh -O autogen.sh
}

install_leveldb() {
    scratch_init leveldb

    wget "https://github.com/google/leveldb/archive/v${LEVELDB_VERSION}.tar.gz"
    untar_to_dir "v${LEVELDB_VERSION}.tar.gz" "leveldb-${LEVELDB_VERSION}"
    cd "leveldb-${LEVELDB_VERSION}"

    LD_FLAGS="-L${LOCAL_INSTALL_DIR}/lib" make -j4

    # leveldb doesn't have a make install target...
    # Instructions below taken from
    # http://techoverflow.net/blog/2012/12/14/compiling-installing-leveldb-on-linux/
    cp --preserve=links libleveldb.* ${LOCAL_INSTALL_DIR}/lib
    cp -r include/leveldb ${LOCAL_INSTALL_DIR}/include/
}

install_openblas() {
    scratch_init openblas

    wget "https://github.com/xianyi/OpenBLAS/archive/v${OPENBLAS_VERSION}.tar.gz" -O "openblas_${OPENBLAS_VERSION}.tar.gz"
    untar_to_dir openblas_${OPENBLAS_VERSION}.tar.gz openblas_${OPENBLAS_VERSION}
    cd openblas_${OPENBLAS_VERSION}

    make -j4
    make PREFIX="${LOCAL_INSTALL_DIR}" install

    # OpenBLAS only installs libopenblas.a, but it provides the symbols for
    # libcblas.a and libatlas.a (I think). Symlinking libatlas and libcblas
    # allows Caffe to build.
    ln -s "${LOCAL_INSTALL_DIR}/lib/libopenblas.a" "${LOCAL_INSTALL_DIR}/lib/libcblas.a"
    ln -s "${LOCAL_INSTALL_DIR}/lib/libopenblas.a" "${LOCAL_INSTALL_DIR}/lib/libatlas.a"
}

install_caffe() {
    mkdir -p "${CAFFE_INSTALL_DIR}"
    cd "${CAFFE_INSTALL_DIR}"

    wget https://github.com/BVLC/caffe/archive/rc2.tar.gz
    untar_to_dir rc2.tar.gz .

    cp Makefile.config.example Makefile.config
    echo "=== Compiling caffe ==="
    CPU_ONLY=1 \
        LDFLAGS="-L${LOCAL_INSTALL_DIR}/lib" \
        make -j4

    echo "=== Compiling caffe python bindings ==="
    python_include_dir="${LOCAL_INSTALL_DIR}/include/python${PYTHON_SHORT_VERSION}"
    numpy_include_dir="${LOCAL_INSTALL_DIR}/lib/python${PYTHON_SHORT_VERSION}/site-packages/numpy/core/include"

    CPU_ONLY=1 \
        CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH}:${python_include_dir}:${numpy_include_dir}" \
        LDFLAGS="-L${LOCAL_INSTALL_DIR}/lib" \
        make pycaffe

    echo "=== If that worked, congrats! One last note: ==="
    echo "You'll need to update your PYTHONPATH in .bashrc/.zshrc as follows:"
    echo 'export PYTHONPATH="'${CAFFE_INSTALL_DIR}'/python:$PYTHONPATH"'
}

echo "=== Installing Protobufs ==="
install_protobufs
echo "=== Installing cmake ==="
install_cmake
echo "=== Installing gflags ==="
install_gflags
echo "=== Installing glog ==="
install_glog
echo "=== Installing opencv ==="
install_opencv
echo "=== Installing hdf5 ==="
install_hdf5
echo "=== Installing python2 ==="
install_python2
echo "=== Installing pip ==="
install_pip
echo "=== Installing libpng ==="
install_libpng
echo "=== Installing automake ==="
install_automake
echo "=== Installing freetype ==="
install_freetype
echo "=== Installing python modules ==="
install_python_modules
echo "=== Installing boost ==="
install_boost
echo "=== Installing lmdb ==="
install_lmdb
echo "=== Installing libtool ==="
install_libtool
echo "=== Installing snappy ==="
install_snappy
echo "=== Installing leveldb ==="
install_leveldb
echo "=== Installing openblas ==="
install_openblas

echo "=== The dependencies are installed! ==="
echo "You likely want to add the following lines to your .bashrc/.zshrc"
echo 'export LD_LIBRARY_PATH="'${LOCAL_INSTALL_DIR}'/lib64:'${LOCAL_INSTALL_DIR}'/lib:$LD_LIBRARY_PATH"'
echo 'export C_INCLUDE_PATH="'${LOCAL_INSTALL_DIR}'/include:$C_INCLUDE_PATH"'
echo 'export CPLUS_INCLUDE_PATH="'${LOCAL_INSTALL_DIR}'/include:$CPLUS_INCLUDE_PATH"'

echo "=== Once you've done that, you can run install_caffe by uncommenting below. ==="
# install_caffe
