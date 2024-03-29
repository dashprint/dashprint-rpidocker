set(CMAKE_C_COMPILER "clang-8")
set(CMAKE_CXX_COMPILER "clang++-8")
set(CMAKE_SYSROOT "/sysroot")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -target arm-linux-gnueabihf -march=armv6 -mfpu=vfp -mfloat-abi=hard -ffunction-sections -fdata-sections --sysroot ${CMAKE_SYSROOT} -fuse-ld=lld" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -target arm-linux-gnueabihf -march=armv6 -mfpu=vfp -mfloat-abi=hard -ffunction-sections -fdata-sections --sysroot ${CMAKE_SYSROOT} -fuse-ld=lld" CACHE STRING "" FORCE)
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -target arm-linux-gnueabihf -fuse-ld=lld --sysroot ${CMAKE_SYSROOT}")
set(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} -target arm-linux-gnueabihf -fuse-ld=lld --sysroot ${CMAKE_SYSROOT}")
set(CMAKE_AR "/usr/bin/ar" CACHE STRING "" FORCE)
set(CMAKE_RANLIB "/usr/bin/ranlib" CACHE STRING "" FORCE)
set(CMAKE_MAKE_PROGRAM "/usr/bin/make" CACHE STRING "" FORCE)
