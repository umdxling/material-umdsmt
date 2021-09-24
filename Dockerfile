# Use ubuntu base image
FROM ubuntu:xenial

# Update
RUN apt-get update
RUN apt-get install -y apt-utils debconf-utils
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && apt-get -y upgrade

# Install some necessary tools.
RUN apt-get install -y nano perl

# Install Moses dependencies.
RUN apt-get install -y libboost-all-dev
RUN apt-get install -y build-essential git-core pkg-config automake libtool wget zlib1g-dev python-dev libbz2-dev cmake

RUN apt-get update && apt-get install --no-install-recommends -y \
    git python3-pip python wget \
    && rm -rf /var/lib/apt/lists
RUN pip3 install --upgrade pip setuptools wheel

# Copy models to the image
# Raw systems
RUN mkdir -p /app/models
COPY ./umd-smt-v3.7.3/raw /app/models/raw
COPY ./umd-smt-v3.7.3/stem /app/models/stem

# Copy scripts to the image
COPY ./scripts /app/scripts
COPY ./configs /app/configs
COPY ./Makefile /app/Makefile

WORKDIR /app
RUN make tools

# Copy current directory contents to docker
RUN mkdir -p /app/output

# Setup entrypoint
ENTRYPOINT ["bash","/app/scripts/decode_load_first.sh"]
