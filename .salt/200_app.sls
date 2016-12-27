{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}
{% import "makina-projects/{0}/redis.j2".format(cfg.name) as redis %}

{{cfg.name}}-git-eol:
  cmd.run:
    - name: git config --global core.autocrlf input && echo changed=false
    - stateful: true
    - user: root

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.name)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}

{{cfg.name}}-rvm-wrapper-loader:
  file.managed:
    - name: {{data.home}}/rvm-loader.sh
    - mode: 750
    - user: {{data.user}}
    - group: {{cfg.group}}
    - contents: |
                #!/usr/bin/env bash
                set -e
                GEMSET="${GEMSET:-"{{cfg.name}}"}";
                RVERSION="${RVERSION:-"{{data.rversion.strip()}}"}"
                . /etc/profile
                . /usr/local/rvm/scripts/rvm
                rvm --create use ${RVERSION}@${GEMSET}

{{cfg.name}}-rvm-wrapper:
  file.managed:
    - name: {{data.home}}/rvm.sh
    - mode: 750
    - user: {{data.user}}
    - group: {{cfg.group}}
    - require:
      - file: {{cfg.name}}-rvm-wrapper-loader
    - contents: |
                #!/usr/bin/env bash
                set -e
                . "{{data.home}}/rvm-loader.sh"
                exec "${@}"

{{cfg.name}}-add-to-rvm:
  user.present:
    - names: [{{data.user}}]
    - optional_groups: [rvm]
    - remove_groups: false

{{cfg.name}}-rubyversion:
  file.managed:
    - name: {{data.dir}}/.ruby-version
    - contents: "ruby-{{data.rversion}}"
    - mode: 750
    - user: {{data.user}}
    - group: {{cfg.group}}
    - template: jinja

{{project_rvm(
     'gem install bundler rake rvm && gem regenerate_binstubs',
      state=cfg.name+'-bundler')}}
    - onlyif: test ! -e /usr/local/rvm/gems/ruby-{{data.rversion}}*@{{cfg.name}}/bin/bundle
    - user: {{data.user}}
    - require:
      - user: {{cfg.name}}-add-to-rvm
      - file: {{cfg.name}}-rubyversion
      - file: {{cfg.name}}-rvm-wrapper

{{project_rvm(
 'bundle install -j{2} --path {0}/gems '
 '--deployment --without kerberos development test {1} aws'.format(
     data.dir, data.db_gem, data.worker_processes),
 state=cfg.name+'-install-gitlab')}}
    - cwd: {{data.dir}}
    - unless: test -e "{{data.dir}}/gems/ruby/2.1.0/gems/pg-0.15.1"
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-bundler'}}

{{project_rvm(
 'rake gitlab:setup force=yes RAILS_ENV=production GITLAB_ROOT_PASSWORD={2} && touch {0}/skip_setup'.format(
     data.home, data.db_gem, data.root_password, data.version),
 state=cfg.name+'-setup-gitlab')}}
    - onlyif: test ! -e {{data.home}}/skip_setup
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-install-gitlab'}}

{{project_rvm(
 'rake gitlab:shell:install[v{3}] REDIS_URL="{4}" RAILS_ENV=production && touch {0}/skip_shell_v{3}'.format(
     data.home, data.db_gem, data.root_password,
     data.shell_version, redis.url(data)),
 state=cfg.name+'-setup-shell')}}
    - onlyif: test ! -e {{data.home}}/skip_shell_v{{data.shell_version}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-setup-gitlab'}}

# stash any changes to git shell first
{{cfg.name}}-stash:
  cmd.run:
    - name: if git diff -q --exit-code; then git stash;fi
    - cwd: "{{data.home}}/gitlab-shell"
    - require:
      - cmd: {{cfg.name+'-setup-shell'}}

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
      - cmd: {{cfg.name+'-setup-shell'}}
      - cmd: {{cfg.name}}-stash
{% endfor %}


{{cfg.name}}-hooks:
  cmd.run:
    - name: "{{data.home}}/wrap_hooks.sh"
    - cwd: {{data.home}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-setup-gitlab'}}
