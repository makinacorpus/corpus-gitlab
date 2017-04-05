{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %} 

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.name)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}
{% if data.gitaly_enabled %}

{{cfg.name}}-pages-dirs:
  file.directory:
    - makedirs: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: "2751"
    - names:
      - "{{data.home}}/gitaly"
    - require_in:
      - cmd: {{cfg.name}}-gitaly-stash

{{cfg.name}}-gitaly-stash:
  cmd.run:
    - name: |
        cd "{{data.home}}/gitaly" || exit 0
        if git diff -q --exit-code; then git stash;fi

{{project_rvm(
   'rake gitlab:gitaly:install[{0}/gitaly] RAILS_ENV=production && touch {0}/skip_gitaly_v{1}'.format(
     data.home,
     data.gitaly_build_id,
     state=cfg.name+'-setup-gitaly')
)}}
    - onlyif: test ! -e {{data.home}}/skip_gitaly_v{{data.gitaly_build_id}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name}}-gitaly-stash
    - require_in:
      - file: {{cfg.name}}gitalyenv

{{cfg.name}}gitalyenv:
  file.managed:
    - name: "{{data.home}}/gitaly/env"
    - contents: |
        GITALY_SOCKET_PATH={{data.dir}}/tmp/sockets/private/gitaly.socket
    - mode: 644
    - user: {{data.user}}

{% else %}
noop:
  mc_proxy.hook: []
{% endif %}
