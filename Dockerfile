FROM debian:buster

LABEL maintainer='ken_zookie'

# --------------- #
# OPTION DEFAULTS #
# --------------- #

# See README.md for description of these options
ENV CONFIG_LOCATION /home/minecraft/config.py
ENV RENDER_MAP "true"
ENV RENDER_POI "true"
ENV RENDER_SIGNS_FILTER "-- RENDER --"
ENV RENDER_SIGNS_HIDE_FILTER "false"
ENV RENDER_SIGNS_JOINER "<br />"
ENV MINECRAFT_VERSION "1.17"

# ---------------------------- #
# INSTALL & CONFIGURE DEFAULTS #
# ---------------------------- #

WORKDIR /home/minecraft/

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        httpie \
        jq \
        optipng \
        python3-dev \
        python3-numpy \
        python3-pil \
        python3-venv \
        python3 \
        unzip \
        wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    groupadd minecraft -g 1000 && \
    useradd -m minecraft -u 1000 -g 1000 && \
    mkdir -p /home/minecraft/render /home/minecraft/server && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
  unzip awscli-bundle.zip && \
  ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

RUN git clone --depth=1 git://github.com/overviewer/Minecraft-Overviewer.git

WORKDIR /home/minecraft/Minecraft-Overviewer/
RUN python3 setup.py build && \
    python3 setup.py install

WORKDIR /home/minecraft/

COPY config/config.py /home/minecraft/config.py
COPY render.sh /home/minecraft/render.sh
COPY download_url.py /home/minecraft/download_url.py
COPY download_client.sh /home/minecraft/download_client.sh
COPY run.sh /home/minecraft/run.sh
RUN cd /home/minecraft && git clone https://github.com/air/minecraft-tools.git

RUN chown minecraft:minecraft -R /home/minecraft/
RUN bash download_client.sh

USER minecraft

CMD ["bash", "/home/minecraft/run.sh"]
