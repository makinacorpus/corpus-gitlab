{% import "makina-states/services/monitoring/circus/macros.jinja" as circus with context %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-states.services.monitoring.circus

# inconditionnaly reboot circus & nginx upon deployments
/bin/true:
  cmd.run:
    - watch_in:
      - mc_proxy: circus-pre-conf

{% set circus_data = {
  'cmd': ('{0}/rvm.sh bin/bundle exec unicorn_rails'
          ' -c config/unicorn.rb -E production').format(
             cfg.project_root),
  'environment': {'RAILS_ENV': 'production'},
  'uid': data.user,
  'gid': data.group,
  'copy_env': True,
  'working_dir': data.dir,
  'warmup_delay': "40",
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name+'-web', **circus_data) }}
{% set circus_data = {
  'cmd': '{0}/rvm.sh bin/background_jobs start_no_deamonize'.format(
    cfg.project_root),
  'environment': {'RAILS_ENV': 'production'},
  'uid': data.user,
  'gid': data.group,
  'copy_env': True,
  'working_dir': data.dir,
  'warmup_delay': "40",
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name+'-jobs', **circus_data) }}
