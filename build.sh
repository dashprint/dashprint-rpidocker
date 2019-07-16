#!/bin/sh

set -e

if [ ! -f docker/sysroot.tar.gz ]; then

    if [ ! -f 2019-04-08-raspbian-stretch-lite.img ]; then
        echo "Downloading Raspbian image..."

        wget http://director.downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-04-09/2019-04-08-raspbian-stretch-lite.zip
        unzip 2019-04-08-raspbian-stretch-lite.zip
        rm -f 2019-04-08-raspbian-stretch-lite.zip
    fi

    offset=$(sfdisk -d 2019-04-08-raspbian-stretch-lite.img | gawk '{ if (match($0, /img2 : start= *([0-9]+)/, m)) print m[1]  }')

    echo "Creating a sysroot archive..."
    mkdir -p sysroot
    mount -t ext4 -o ro,offset=$((512*offset)) 2019-04-08-raspbian-stretch-lite.img sysroot
    tar czf docker/sysroot.tar.gz sysroot
    umount sysroot
    rmdir sysroot
fi

echo "Building a Docker image..."
cd docker
docker build -t lubosd/dashprint-rpidocker:1.0 .

echo "Updating Raspbian..."

rm -f image.cid

docker run --privileged --cidfile image.cid -i lubosd/dashprint-rpidocker:1.0 /bin/bash -s <<END
set -e
mount -t binfmt_misc none /proc/sys/fs/binfmt_misc
update-binfmts --enable
mount -o bind /proc /sysroot/proc && mount -o bind /dev /sysroot/dev && mount -o bind /sys /sysroot/sys
chroot /sysroot /bin/bash -c 'apt-get update && apt-get install -y libssl-dev libraspberrypi-dev zlib1g-dev libudev-dev symlinks && apt-get clean && cd /usr/lib/arm-linux-gnueabihf && symlinks -c .'
END

docker commit $(cat image.cid) lubosd/dashprint-rpidocker:1.0
docker rm $(cat image.cid)

echo "Compiling libc++(abi)..."
rm -f image.cid

docker run --cidfile image.cid -i lubosd/dashprint-rpidocker:1.0 /bin/bash -s <<END
set -e
cd /root
wget https://github.com/llvm-mirror/libcxxabi/archive/master.zip -O libcxxabi.zip
wget https://github.com/llvm-mirror/libcxx/archive/master.zip -O libcxx.zip
unzip libcxxabi.zip && rm libcxxabi.zip
unzip libcxx.zip && rm libcxx.zip

cd /root/libcxxabi-master
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/Toolchain-rpi-cxx.cmake -DLIBCXXABI_LIBCXX_INCLUDES=/root/libcxx-master/include -DLIBCXXABI_ENABLE_SHARED=Off
make -j4 install DESTDIR=/sysroot/

cd /root/libcxx-master
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/Toolchain-rpi-cxx.cmake -DLIBCXX_ENABLE_SHARED=Off -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_CXX_ABI_INCLUDE_PATHS=/root/libcxxabi-master/include
make -j4 install DESTDIR=/sysroot/

cd /root && rm -rf libcxxabi-master libcxx-master
END

docker commit $(cat image.cid) lubosd/dashprint-rpidocker:1.0
docker rm $(cat image.cid)

echo "Compiling Boost..."
rm -f image.cid

docker run --cidfile image.cid -i lubosd/dashprint-rpidocker:1.0 /bin/bash -s <<END
#set -e
cd /root
wget https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.bz2
tar xf boost_1_70_0.tar.bz2 && rm boost_1_70_0.tar.bz2
cd boost_1_70_0

./bootstrap.sh --with-toolset=clang
echo -e 'using clang : 8.0.0 : clang++-8 : <compileflags>-stdlib=libc++ <compileflags>--sysroot=/sysroot <compileflags>-target <compileflags>arm-linux-gnueabihf <compileflags>-march=armv6 <compileflags>-mfpu=vfp <compileflags>-mfloat-abi=hard <compileflags>-ffunction-sections <compileflags>-fdata-sections <linkflags>-target <linkflags>arm-linux-gnueabihf <linkflags>-fuse-ld=lld <linkflags>--sysroot=/sysroot <abi>aapcs <address-model>32 <architecture>arm <binary-format>elf <threading>multi <toolset>clang <sysroot>/sysroot ;' > ./tools/build/src/user-config.jam

./bjam --toolset=clang-8.0.0 link=static abi=aapcs address-model=32 architecture=arm binary-format=elf threading=multi --prefix=/sysroot/usr/local -j4 install
cd .. && rm -rf boost_1_70_0
END

docker commit $(cat image.cid) lubosd/dashprint-rpidocker:1.0
docker rm $(cat image.cid)

echo "Compiling libavformat..."
rm -f image.cid

docker run --cidfile image.cid -i lubosd/dashprint-rpidocker:1.0 /bin/bash -s <<END
set -e

cd /root
wget https://ffmpeg.org/releases/ffmpeg-4.1.4.tar.bz2
tar xf ffmpeg-4.1.4.tar.bz2 && rm -f ffmpeg-4.1.4.tar.bz2
cd ffmpeg-4.1.4

CFLAGS="--target=arm-linux-gnueabihf -ffunction-sections -fdata-sections" LDFLAGS="-fuse-ld=lld --target=arm-linux-gnueabihf" ./configure --disable-avdevice --disable-swresample --disable-swscale --disable-postproc --disable-avfilter --disable-encoders --disable-decoders --disable-protocols --disable-muxers --enable-muxer=mp4 --disable-demuxers --enable-demuxer=h264 --disable-bsfs --enable-bsf=h264_metadata --disable-parsers --enable-parser=h264 --disable-network --enable-small --enable-cross-compile --sysroot=/sysroot --arch=armhf --target-os=linux --cc=clang-8 --cpu=arm1176jzf-s --disable-asm --host_cc=clang-8 --disable-ffprobe

make -j4
make install DESTDIR=/sysroot

cd /root
rm -rf ffmpeg-4.1.4
END

docker commit $(cat image.cid) lubosd/dashprint-rpidocker:1.0
docker rm $(cat image.cid)

