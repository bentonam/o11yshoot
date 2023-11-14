FROM debian:stable-slim as fetcher
COPY build/fetch-tools.sh /tmp/fetch-tools.sh

RUN apt-get update && apt-get install -y \
  curl \
  wget \
  unzip

RUN /tmp/fetch-tools.sh

FROM nicolaka/netshoot

RUN set -ex \
    apk add --no-cache \
    lnav

# install downloaded binaries from fetcher
COPY --from=fetcher /tmp/* /usr/local/bin/

CMD ["zsh"]
