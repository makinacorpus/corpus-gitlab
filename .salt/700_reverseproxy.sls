{% import "makina-states/services/http/nginx/init.sls" as nginx %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
include:
  - makina-states.services.http.nginx

{{ nginx.virtualhost(
    vhost_basename="corpus-gitlab",
    domain=data.domain,
    doc_root=data.dir+'/public',
    vh_top_source=data.nginx_upstreams,
    vh_content_source=data.nginx_vhost,
    force_restart=True,
    cfg=cfg)}}

{% if data.pages_enabled %}
{{ nginx.virtualhost(
    vhost_basename="corpus-gitlabpages",
    domain=data.pages_host,
    server_name="~^.*{0}$".format(data.pages_host),
    doc_root=data.dir+'/public',
    vh_top_source=data.nginx_pages_upstreams,
    vh_content_source=data.nginx_pages_vhost,
    force_restart=True,
    cfg=cfg)}}
{% endif %}

{% if data.registry_enabled %}
{{ nginx.virtualhost(
    vhost_basename="corpus-dockerregistry",
    domain=data.registry_host,
    doc_root=data.dir+'/public',
    vh_top_source=data.nginx_containerregistry_upstreams,
    vh_content_source=data.nginx_containerregistry_vhost,
    force_restart=True,
    cfg=cfg)}}
{% endif %}
