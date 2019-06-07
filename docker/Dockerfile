FROM debian:stable

ADD sysroot.tar.gz /

RUN sed -i "s#http://deb.debian.org/debian#http://ftp.cz.debian.org/debian#" /etc/apt/sources.list
RUN echo 'deb http://ftp.cz.debian.org/debian unstable main' > /etc/apt/sources.list.d/unstable.list && \
    echo 'deb http://ftp.cz.debian.org/debian testing main' > /etc/apt/sources.list.d/testing.list && \
    echo 'APT::Default-Release "stable";' > /etc/apt/apt.conf.d/99defaultrelease

RUN apt-get update && apt-get install -y wget unzip make
RUN apt-get -t unstable install -y clang-8 lld-8
RUN apt-get -t testing install -y cmake
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-8 100 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 100

RUN apt-get install -y qemu-user-static
RUN cp /usr/bin/qemu-arm-static /sysroot/usr/bin
RUN sed -i "s/.*libcofi_rpi.so//" /sysroot/etc/ld.so.preload

# Used for libc++ and libc++abi build
ADD Toolchain-rpi-cxx.cmake /root

RUN cd /opt && \
    wget https://nodejs.org/dist/v10.16.0/node-v10.16.0-linux-x64.tar.xz && \
    tar xf node-v10.16.0-linux-x64.tar.xz && \
    rm -f node-v10.16.0-linux-x64.tar.xz
ENV PATH="/opt/node-v10.16.0-linux-x64/bin:${PATH}"

RUN npm install -g @angular/cli
RUN apt-get clean
