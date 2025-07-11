promtail:
  config:
    logLevel: ${promtail_log_level}
    serverPort: ${promtail_server_port}
    clients:
%{~ for c in promtail_clients }
      - url: ${c}
%{ endfor }
    logFormat: ${log_format}
    snippets:
%{ if length(promtail_extra_label_configs_raw) > 0 }
      extraRelabelConfigs:
      ${indent(6, promtail_extra_label_configs_yaml)}
%{ else }
      extraRelabelConfigs: []
%{ endif }
%{ if length(promtail_extra_scrape_configs) > 0 }
      extraScrapeConfigs: |
        ${indent(8, promtail_extra_scrape_configs)}
%{ else }
      extraScrapeConfigs: ""
%{ endif }
