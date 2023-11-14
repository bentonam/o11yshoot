#!/usr/bin/env bash

GITHUB_URL="https://github.com"
API_URL="https://api.github.com/repos"
TMP_DIR="/tmp"

HOST_OS=$(uname -a | awk '{print tolower($1)}' || true)
HOST_ARCH=$(uname -m)

if [[ "${HOST_ARCH}" == "x86_64" ]]; then
  HOST_ARCH=amd64
elif [[ "${HOST_ARCH}" == "aarch64" ]]; then
  HOST_ARCH=arm64
fi

echo "HOST_OS: ${HOST_OS}"
echo "HOST_ARCH: ${HOST_ARCH}"

getLatestRelease() {
  local org="${1}"
  local repo="${2}"
  local releases_url="${API_URL}/${org}/${repo}/releases/latest"
  local header_token='Authorization: Bearer ${{ secrets.GHCR_TOKEN }}'
  # check to see if a token exists in the environment
  if ! [[ -z "${GHCR_TOKEN+x}" ]]; then
    header_token="Authorization: Bearer ${GHCR_TOKEN}"
  fi

  local version
  version=$(
    wget --header="${header_token}" -q -O - "${releases_url}" \
      | grep -m 1 tag_name  \
      | sed -E 's/[^:]+ *"[^0-9]*([^"]+)".*/\1/' || true
  )

  echo "${version}"
}

install() {
  local org="${1}"
  local repo="${2}"
  local binary="${3}"
  local download_file_path="${4}"
  local download_url="${GITHUB_URL}/${org}/${repo}/releases/download"
  local version
  version=$(getLatestRelease "${org}" "${repo}")

  echo "Installing ${binary} v${version} from ${GITHUB_URL}/${org}/${repo}"

  download_file_path="${download_file_path//\{\{repo\}\}/${repo}}"
  download_file_path="${download_file_path//\{\{binary\}\}/${binary}}"
  download_file_path="${download_file_path//\{\{arch\}\}/${HOST_ARCH}}"
  download_file_path="${download_file_path//\{\{version\}\}/${version}}"
  download_file_path="${download_file_path//\{\{os\}\}/${HOST_OS}}"

  echo "download_file_path: ${download_file_path}"
  download_url="${download_url}/${download_file_path}"
  echo "download_url: ${download_url}"

  local saved_filename
  saved_filename=$(basename "${download_file_path}")
  echo "saved_filename: ${saved_filename}"

  # download the file to /tmp
  wget -q -O "${TMP_DIR}/${saved_filename}" "${download_url}"

  if [[ "${download_file_path}" == *.tar.gz ]]; then
    ( cd "${TMP_DIR}" || exit ; tar -xvf "${TMP_DIR}/${saved_filename}" )
    # generate a directory name from the tar archive
    local new_dir="${saved_filename//.tar.gz/}"
    # find the binary in the directory and move it, if it exists
    if [[ -d "${TMP_DIR}/${new_dir}" ]]; then
      find "${TMP_DIR}/${new_dir}/" -type f -name "${binary}*" -exec sh -c "mv {} ${TMP_DIR}/${binary}" \;
    else
      # it was extracted to ${TMP_DIR}
      find "${TMP_DIR}/" -type f -name "${binary}-*" -exec sh -c "mv {} ${TMP_DIR}/${binary}" \;
    fi
    # remove the directory and archive
    rm -rf "${TMP_DIR:?}/${saved_filename}" "${TMP_DIR:?}/${new_dir}"

  elif [[ "${download_file_path}" == *.zip ]]; then
    unzip -qq -o -d "${TMP_DIR}" "${TMP_DIR}/${saved_filename}"
    rm -rf "${TMP_DIR:?}/${saved_filename}"
    find "${TMP_DIR}/" -type f -name "${binary}-*" -exec sh -c "mv {} ${TMP_DIR}/${binary}" \;

  else
    mv "${TMP_DIR}/${saved_filename}" "${TMP_DIR}/${binary}"
  fi

  chmod +x "${TMP_DIR}/${binary}"
}

# mimirtool is a command-line tool that operators and tenants can use to execute a number of common tasks that involve Grafana Mimir
# or Grafana Cloud Metrics.
install "grafana" "mimir" "mimirtool" "{{repo}}-{{version}}/{{binary}}-{{os}}-{{arch}}"

# metaconvert is a tool to update meta.json files to conform to Mimir requirements
install "grafana" "mimir" "metaconvert" "{{repo}}-{{version}}/{{binary}}-{{os}}-{{arch}}"

# query-tee is a standalone tool that you can use for testing purposes when comparing the query results and performance of two Grafana
# Mimir clusters. The two Mimir clusters compared by the query-tee must ingest the same series and samples
install "grafana" "mimir" "query-tee" "{{repo}}-{{version}}/{{binary}}-{{os}}-{{arch}}"

# Used to manage folders, dashboards, data sources, Prometheus rules, Synthetic monitoring, and more
install "grafana" "grizzly" "grr" "v{{version}}/{{binary}}-{{os}}-{{arch}}"

# LogCLI is the command-line interface to Grafana Loki. It facilitates running LogQL queries against a Loki instance.
install "grafana" "loki" "logcli" "v{{version}}/{{binary}}-{{os}}-{{arch}}.zip"

# Promtail is an agent which ships the contents of local logs to a private Grafana Loki instance or Grafana Cloud.
install "grafana" "loki" "promtail" "v{{version}}/{{binary}}-{{os}}-{{arch}}.zip"

# promtool is used to view/check configuration, perform queries, inspect tsdb
install "prometheus" "prometheus" "promtool" "v{{version}}/{{repo}}-{{version}}.{{os}}-{{arch}}.tar.gz"

# amtool is used to view and modify the current Alertmanager state, validate the config, test templates, etc.
install "prometheus" "alertmanager" "amtool" "v{{version}}/{{repo}}-{{version}}.{{os}}-{{arch}}.tar.gz"

# pint is a Prometheus Rule Linter from Cloudflare that checks for common mistakes and helps you write better rules.
install "cloudflare" "pint" "pint" "v{{version}}/{{repo}}-{{version}}-{{os}}-{{arch}}.tar.gz"

# jq is for processing json
install "jqlang" "jq" "jq" "jq-{{version}}/{{binary}}-{{os}}-{{arch}}"

# yq is for processing yaml
install "mikefarah" "yq" "yq" "v{{version}}/{{binary}}_{{os}}_{{arch}}"
