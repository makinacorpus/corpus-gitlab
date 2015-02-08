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
  'warmup_delay': "30",
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name+'-web', **circus_data) }}
{% set circus_data = {
  'cmd': '{0}/rvm.sh bin/bundle exec sidekiq -t 1 -q post_receive -q mailer -q system_hook -q project_web_hook -q gitlab_shell -q common -q default -e {1}'.format(
    cfg.project_root, 'production'),
  'environment': {'RAILS_ENV': 'production'},
  'uid': data.user,
  'gid': data.group,
  'copy_env': True,
  'working_dir': data.dir,
  'warmup_delay': "30",
  'stop_children': True,
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name+'-jobs', **circus_data) }}
