{% import "makina-states/services/http/nginx/init.sls" as nginx %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-states.services.http.nginx

# inconditionnaly reboot circus & nginx upon deployments
/bin/true:
  cmd.run:
    - watch_in:
      - mc_proxy: nginx-pre-conf-hook

{{ nginx.virtualhost(
    domain=data.domain,
    doc_root=data.dir+'/public',
    vh_top_source=data.nginx_upstreams,
    vh_content_source=data.nginx_vhost,
    cfg=cfg)}}
