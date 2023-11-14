FROM debian:stable-slim as fetcher
COPY build/fetch-tools.sh /tmp/fetch-tools.sh

RUN apt-get update && apt-get install -y \
  curl \
  wget \
  tar \
  unzip

RUN /tmp/fetch-tools.sh && rm /tmp/fetch-tools.sh

FROM nicolaka/netshoot

RUN set -ex \
    apk add --no-cache \
    lnav \
    curl \
    wget \
    golang-go

# install downloaded binaries from fetcher
COPY --from=fetcher /tmp/* /usr/local/bin/

RUN ls -lathr /usr/local/bin

CMD ["zsh"]
