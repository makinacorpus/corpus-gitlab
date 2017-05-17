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

{{cfg.name}}-gitaly-dirs:
  file.directory:
    - makedirs: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: "2751"
    - names:
      - "{{data.gitaly_dir}}"
    - require_in:
      - cmd: {{cfg.name}}-gitaly-stash

{{cfg.name}}-gitaly-stash:
  cmd.run:
    - name: |
        cd "{{data.gitaly_dir}}" || exit 0
        if git diff -q --exit-code; then git stash;fi
    - require_in:
      - mc_proxy: {{cfg.name}}-install-pre
  #mc_git.latest:
  #  - name: "{{data.gitaly_url}}"
  #  - target: "{{data.gitaly_dir}}"
  #  - user: "{{data.user}}"
  #  - rev: "{{data.gitaly_version}}"
  #  - require_in:
  #    - mc_proxy: {{cfg.name}}-install-pre

{{cfg.name}}-install-pre:
  mc_proxy.hook: []


{{project_rvm(
   'rake gitlab:gitaly:install[{0}/gitaly] RAILS_ENV=production && touch {0}/skip_gitaly_{1}'.format(
     data.home,
     data.gitaly_version,
     state=cfg.name+'-setup-gitaly')
)}}
    - onlyif: test ! -e {{data.home}}/skip_gitaly_{{data.gitaly_version}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - mc_proxy: {{cfg.name}}-install-pre
    - require_in:
      - file: {{cfg.name}}gitalyenv

{{cfg.name}}gitalyconf:
  file.managed:
    - name: "{{data.home}}/gitaly/config.toml"
    - contents: |
                socket_path = "{{data.dir}}/tmp/sockets/private/gitaly.socket"

                [[storage]]
                name = "default"
                path = "{{data.repos_path}}"

    - mode: 644
    - user: {{data.user}}

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
