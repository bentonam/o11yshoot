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
    go


COPY --from=golang:1.21-alpine3.18 /usr/local/go/ /usr/local/go/

# install downloaded binaries from fetcher
COPY --from=fetcher /tmp/* /usr/local/bin/

ENV PATH="/usr/local/go/bin:${PATH}"

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && \
  chmod -R 777 "$GOPATH" && \
  go install github.com/grafana/memo/cmd/...@latest && \
  go install github.com/grafana/unused/cmd/unused@latest && \
  go install github.com/grafana/dashboard-linter@latest && \
  ls -lathr /usr/local/bin && \
  ls -lathr /go/bin

CMD ["zsh"]
