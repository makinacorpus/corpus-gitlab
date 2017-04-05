{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set project_root=cfg.project_root %}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}
{% import "makina-projects/{0}/redis.j2".format(cfg.name) as redis %}

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.name)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}

include:
  - makina-projects.{{cfg.name}}.include.configs


{{cfg.name}}-shell-dirs:
  file.directory:
    - makedirs: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: "2751"
    - names:
      - "{{data.home}}/gitaly"
    - require_in:
      - cmd: {{cfg.name}}-shell-stash

{{cfg.name}}-shell-stash:
  cmd.run:
    - name: |
        if [ -e "{{data.home}}/gitlab-shell" ];then
          cd "{{data.home}}/gitlab-shell"
          if git diff -q --exit-code; then git stash;fi
        fi

{{project_rvm(
 'rake gitlab:shell:install[v{3}] REDIS_URL="{4}" RAILS_ENV=production && touch {0}/skip_shell_v{3}'.format(
     data.home, data.db_gem, data.root_password,
     data.shell_version, redis.url(data)),
 state=cfg.name+'-setup-shell')}}
    - onlyif: test ! -e {{data.home}}/skip_shell_v{{data.shell_version}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name}}-shell-stash
    - require_in:
      - mc_proxy: {{cfg.name}}-shell-configs

{{cfg.name}}-shell-configs:
  mc_proxy.hook:
    - require_in:
      - mc_proxy: {{cfg.name}}-shell-configs-post

{{cfg.name}}-shell-configs-post:
  mc_proxy.hook: []

{% for i in ['config.yml'] %}
{{cfg.name}}-{{i}}:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/cfg/{{i}}
    - name:  {{data.home}}/gitlab-shell/{{i}}
    - template: jinja
    - mode: 770
    - user: "{{data.user}}"
    - group: "root"
    - defaults:
        project: {{cfg.name}}
    - require:
      - mc_proxy: {{cfg.name}}-shell-configs
    - require_in:
      - mc_proxy: {{cfg.name}}-shell-configs-post
{% endfor %}

{{cfg.name}}-hooks-wrapper:
  file.managed:
    - makedirs: true
    - name: "{{data.home}}/wrap_hooks.sh"
    - contents: |
                #!/usr/bin/env bash
                set -e
                set -x
                GS="${1:-{{data.home}}/gitlab-shell}"
                cd "${GS}"
                git stash
                cd hooks
                for i in $(ls -1 *|grep -v real);do
                    cp "${i}" "${i}.real.rb"
                    echo "#/usr/bin/env bash">"${i}"
                    echo ". {{data.home}}/rvm_env.sh">>"${i}"
                    echo "exec ruby ./hooks/${i}.real.rb \"\${@}\"">>"${i}"
                done
    - mode: 755
    - group: "root"
    - user: {{data.user}}
    - require:
      - mc_proxy: {{cfg.name}}-shell-configs
    - require_in:
      - mc_proxy: {{cfg.name}}-shell-configs-post

{{cfg.name}}-hooks:
  cmd.run:
    - runas: {{cfg.user}}
    - name: "{{data.home}}/wrap_hooks.sh"
    - require:
      - mc_proxy: {{cfg.name}}-shell-configs-post

