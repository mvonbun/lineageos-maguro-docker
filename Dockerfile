FROM ubuntu:latest
MAINTAINER Michael Vonbun <m.vonbun@gmail.com>

# docker image for building LineageOS 13.0 for Samsung Galaxy Maguro

# sources
# general information can be found at
#   https://wiki.lineageos.org/devices/maguro
# this docker image is based on the LineageOS build tutorial:
#   https://wiki.lineageos.org/devices/maguro/build
# jdk-7
#   https://askubuntu.com/questions/761127/how-do-i-install-openjdk-7-on-ubuntu-16-04-or-higher

# add required packages
RUN apt-get update -y \
    && apt-get install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg \
    gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool \
    libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils \
    lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev maven \
    wget software-properties-common python-minimal


# download and add adb and fastboot
WORKDIR /usr/local/bin
RUN wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip && \
    unzip platform-tools-latest-linux.zip -d . && \
    rm platform-tools-latest-linux.zip


# create workspace directory
WORKDIR /workspace


# add java jdk 7 as we will be building LineageOS 13.0 for maguro
# configure apt to get only openjdk-7 and its dependencies when adding debian experimental
RUN echo 'Package: *\n\
Pin: release o=Debian,n=experimental\n\
Pin-Priority: -1\n\n\
Package: *\n\
Pin: release o=Debian,n=sid\n\
Pin-Priority: -1\n\
\n\
Package: openjdk-7-jdk\n\
Pin: release o=Debian,n=experimental\n\
Pin-Priority: 500\n\
\n\
Package: openjdk-7-jre\n\
Pin: release o=Debian,n=experimental\n\
Pin-Priority: 500\n\
\n\
Package: openjdk-7-jre-headless\n\
Pin: release o=Debian,n=experimental\n\
Pin-Priority: 500\n\
\n\
Package: libjpeg62-turbo\n\
Pin: release o=Debian,n=sid\n\
Pin-Priority: 500\n'\
 >> /etc/apt/preferences.d/debian && \
apt install debian-archive-keyring
# && \

# try to add debian experimental
# it may fail with NO_PUBKEY error which we catch and add the public keys
RUN \
add-apt-repository 'deb http://httpredir.debian.org/debian experimental main' > \
deb_add_apt_out.log 2>deb_add_apt_error.log; \
if [ $? -ne 0 ]; then \
echo "DEBAIN EXPERIMENTAL PUBKEYS UNKOWN => ADDING PUBKEYS"; \
grep --only-matching -P "NO_PUBKEY \K[0-9A-Fa-f]{16,}" deb_add_apt_error.log | \
xargs apt-key adv --keyserver keyserver.ubuntu.com --recv-keys; \
add-apt-repository 'deb http://httpredir.debian.org/debian experimental main'; \
fi && \
add-apt-repository 'deb http://httpredir.debian.org/debian sid main' && \
apt update && \
apt install -y openjdk-7-jdk && \
update-java-alternatives -s java-1.7.0-openjdk-amd64


# add repo tool
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > \
/usr/local/bin/repo && \
chmod a+x /usr/local/bin/repo


# add build folder
RUN mkdir -p ./android/lineage && cd ./android/lineage
RUN repo init -u https://github.com/LineageOS/android.git -b cm-13.0 && repo sync
# RUN source build/envsetup.sh && breakfast maguro > \
# /workspace/breakfast_out.log 2>/workspace/breakfast_error.log; exit 0

# add adb and fastboot path
ENV PATH /usr/local/bin/platform-tools:$PATH

VOLUME ["/workspace"]
