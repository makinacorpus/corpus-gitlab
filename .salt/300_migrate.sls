{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}
{% import "makina-projects/{0}/redis.j2".format(cfg.name) as redis with context %}

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.name)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}
{% for cmd in [
 ('bundle install -j{5} --path {0}/gems '
  '--deployment --without development test {1} aws'),
 'rake db:migrate        RAILS_ENV=production',
 'rake assets:clean      RAILS_ENV=production',
 'rake assets:precompile RAILS_ENV=production',
 'rake cache:clear       RAILS_ENV=production',
] %}
{{project_rvm(
 cmd.format(
     data.home, data.db_gem, data.root_password,
     data.shell_version, redis.url(data), data.worker_processes),
 state=cfg.name+'-{0}'.format(cmd))}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
{% endfor %}
