{% import "makina-states/services/monitoring/circus/macros.jinja" as circus with context %}
{% import "makina-states/services/http/nginx/init.sls" as nginx %}

{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}

include:
  - makina-states.services.http.nginx
  - makina-states.services.monitoring.circus

# inconditionnaly reboot circus & nginx upon deployments
/bin/true:
  cmd.run:
    - watch_in:
      - mc_proxy: nginx-pre-conf-hook
      - mc_proxy: circus-pre-conf

{% set circus_data = {
    'cmd': '../rvm.sh bundle exec puma -e production -p {0}'.format(cfg.data.port),
  'environment': {'RAILS_ENV': 'production'},
  'uid': cfg.user,
  'gid': cfg.group,
  'copy_env': True,
  'working_dir': cfg.project_root+'/redmine',
  'warmup_delay': "10",
  'max_age': 24*60*60}%}

{{ circus.circusAddWatcher(cfg.name, **circus_data) }}
{{ nginx.virtualhost(
    domain=data.domain, 
    doc_root=cfg.project_root+'/redmine/public',
    vh_top_source=data.nginx_upstreams,
    vh_content_source=data.nginx_vhost,
    cfg=cfg)}}
