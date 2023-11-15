# o11ykit

A Docker and Kubernetes network troubleshooting container built from [nicolaka/netshoot](https://github.com/nicolaka/netshoot/tree/master) for Grafana, Mimir, Loki, Tempo, Prometheus and AlertManager.

In addition to everything that [netshoot](https://github.com/nicolaka/netshoot/tree/master) has installed, o11yshoot adds the following command line tools:

-   [amtool](https://github.com/prometheus/alertmanager): View and modify the current Alertmanager state, validate the config, test templates, etc.
-   [dashboard-linter](https://github.com/grafana/dashboard-linter): Perform linting of individual Grafana Dashboards against Best Practices
-   [grizzly](https://github.com/grafana/grizzly): Used to manage folders, dashboards, data sources, Prometheus rules, Synthetic monitoring, and more
-   [logcli](https://grafana.com/docs/loki/latest/tools/logcli):  LogCLI is the command-line interface to Grafana Loki. It facilitates running LogQL queries against a Loki instance.
-   [memo](https://github.com/grafana/memo): Listen for messages on slack, and create grafana annotations automatically, or create annotations directly from the command-line
-   [metaconvert](https://github.com/grafana/mimir): A tool to update meta.json files to conform to Mimir requirements
-   [mimirtool](https://grafana.com/docs/mimir/latest/operators-guide/tools/mimirtool): Mimirtool is a command-line tool that operators and tenants can use to execute a number of common tasks that involve Grafana Mimir or Grafana Cloud Metrics.
-   [pint](https://cloudflare.github.io/pint): Prometheus Rule Linter from Cloudflare
-   [promtail](https://grafana.com/docs/loki/latest/clients/promtail) Promtail is an agent which ships the contents of local logs to a private Grafana Loki instance or Grafana Cloud.
-   [promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/): View/check configuration, perform queries, inspect tsdb
-   [query-tee](https://grafana.com/docs/mimir/latest/operators-guide/tools/query-tee): standalone tool that you can use for testing purposes when comparing the query results and performance of two Grafana Mimir clusters. The two Mimir clusters compared by the query-tee must ingest the same series and samples.
-   [unused](https://github.com/grafana/unused): List your unused persistent disks in different cloud providers, or expose as an exporter
-   [lnav](https://lnav.org) An advanced log file viewer

To use as a plugin in [k9s](https://k9scli.io), add the following to your `plugin.yml`

```yaml
---
plugin:
  # Create debug container for selected pod in current namespace
  # See https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container
  debug:
    shortCut: Shift-D
    description: Add debug container
    scopes:
      - containers
    command: bash
    background: false
    confirm: true
    args:
      - -c
      - "kubectl debug -it -n=$NAMESPACE $POD --target=$NAME --image=bentonam/o11yshoot --share-processes -- bash"
```

**Note** on macOS the `config.yml` and `plugin.yml` default directory is `~/Library/Application Support/k9s`, if you want to move it to `~/.config/k9s` instead do the following:

```bash
mkdir -p ~/.config/k9s
mv ~/Library/Application\ Support/k9s/config.yml ~/.config/k9s
mv ~/Library/Application\ Support/k9s/plugin.yml ~/.config/k9s
rm -rf ~/Library/Application\ Support/k9s/
ln -s ~/.config/k9s/ ~/Library/Application\ Support/k9s
```
