{% import "makina-states/services/monitoring/circus/macros.jinja" as circus with context %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

{{cfg.name}}-service:
  file.copy:
    - source: {{data.dir}}/lib/support/init.d/gitlab
    - name: /etc/init.d/gitlab
    - force: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: 750
  service.running:
    - name: gitlab
    - enable: true
    - watch:
        - file: {{cfg.name}}-service
{#
include:
  - makina-states.services.monitoring.circus

# inconditionnaly reboot circus & nginx upon deployments
{% set circus_data = {
  'cmd': ('{0}/rvm.sh bin/bundle exec unicorn_rails'
          ' -c config/unicorn.rb -E production').format(
             cfg.data.home),
  'environment': {'RAILS_ENV': 'production'},
  'uid': data.user,
  'gid': cfg.group,
  'copy_env': True,
  import epdb;epdb.serve();  ## Breakpoint ##
  'force_reload': t rue,
  'working_dir': data.dir,
  'warmup_delay': "30",
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name+'-web', **circus_data) }}
{% set circus_data = {
  'cmd': '{0}/rvm.sh bin/bundle exec sidekiq -t 1 -q post_receive -q mailer -q system_hook -q project_web_hook -q gitlab_shell -q common -q default -e {1}'.format(
    cfg.data.home, 'production'),
  'environment': {'RAILS_ENV': 'production'},
  'uid': data.user,
  'gid': cfg.group,
  'copy_env': True,
  'working_dir': data.dir,
  'warmup_delay': "30",
  'stop_children': True,
  'force_reload': true,
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name+'-jobs', **circus_data) }}
#}
