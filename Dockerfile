FROM ubuntu:focal

# Install prerequisites
RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        cabextract \
        gosu \
        gpg-agent \
        p7zip \
        pulseaudio-utils \
        software-properties-common \
        tzdata \
        unzip \
        wget \
        winbind \
        zenity \
    && rm -rf /var/lib/apt/lists/*

# Install wine
RUN wget -O- -nv https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --install-recommends winehq-stable \
    && rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget -nv https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/bin/winetricks \
    && chmod +x /usr/bin/winetricks

# Download gecko and mono installers
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN /root/download_gecko_and_mono.sh

# Install lich dependencies
RUN apt-get -y update
RUN apt-get -y install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libsqlite3-dev unzip

# Install ruby
RUN apt-get -y install git curl
RUN groupadd --gid 1010 wineuser
RUN useradd -m wineuser -p wineuser --uid 1010 --gid 1010
USER wineuser
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN ~/.rbenv/bin/rbenv install 2.5.1
RUN echo 'rbenv local 2.5.1' >> ~/.bashrc
RUN echo "gem: --no-document" > ~/.gemrc

USER root
COPY pulse-client.conf /root/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]
