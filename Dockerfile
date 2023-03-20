FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list && \
    apt-get update && apt build-dep -y qt6-base && \
    apt-get install -y git build-essential python3 \
                       libxcb-xinerama0-dev libxcb-util-dev flex bison gperf libicu-dev libxslt-dev ruby \
                       libssl-dev libxcursor-dev libxcomposite-dev libxdamage-dev \
                       libxrandr-dev libdbus-1-dev libfontconfig1-dev libcap-dev libxtst-dev \
                       libpulse-dev libudev-dev libpci-dev libnss3-dev libasound2-dev \
                       libxss-dev libegl1-mesa-dev gperf bison libasound2-dev \
                       libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libx11-xcb-dev \
                       libicu-dev libelf-dev libdw-dev libzstd-dev wget p7zip-full vim
ADD ./build.sh /root/build.sh
RUN chmod +x /root/build.sh

WORKDIR /root
ENTRYPOINT /bin/bash /root/build.sh
