{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm.sls" as rvm with context %}

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.name)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}

{{cfg.name}}-rvm-wrapper-env:
  file.managed:
    - name: {{data.dir}}/rvm-env.sh
    - mode: 750
    - user: {{data.user}}
    - group: {{cfg.group}}
    - contents: |
                #!/usr/bin/env bash
                set -e

                CWD="${PWD}";
                GEMSET="${GEMSET:-"{{cfg.name}}"}";
                RVERSION="${RVERSION:-"{{data.rversion.strip()}}"}"

                . /etc/profile
                . /usr/local/rvm/scripts/rvm
                rvm --create use ${RVERSION}@${GEMSET}

{{cfg.name}}-rvm-wrapper:
  file.managed:
    - name: {{data.dir}}/rvm.sh
    - mode: 750
    - user: {{data.user}}
    - group: {{cfg.group}}
    - require:
      - file: {{cfg.name}}-rvm-wrapper-env
    - contents: |
                #!/usr/bin/env bash
                set -e
                cd "${CWD}"
                . ./rvm-env.sh
                exec "${@}"

{{cfg.name}}-add-to-rvm:
  user.present:
    - names: [{{data.user}}, {{data.user}}]
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
 '--deployment --without development test {1} aws'.format(
     data.dir, data.db_gem, data.worker_processes),
 state=cfg.name+'-install-gitlab')}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-bundler'}}

{{project_rvm(
 'rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD={2} && touch {0}/setup_done'.format(
     data.dir, data.db_gem, data.root_password),
 state=cfg.name+'-setup-gitlab')}}
    - onlyif: test ! -e {{data.dir}}/setup_done
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-install-gitlab'}}
{#
{{project_rvm(
 'rake generate_secret_token'.format(cfg.data_root),
 state=cfg.name+'-install-session')}}
    - cwd: {{data.dir}}
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-install-redmine'}}

{{project_rvm(
 'rake db:migrate --trace'.format(cfg.data_root), state=cfg.name+'-migrate')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-install-session'}}


{{project_rvm(
 'rake redmine:plugins:migrate --trace'.format(cfg.data_root), state=cfg.name+'-plugins-migrate')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{data.user}}
    - require:
      - cmd: {{cfg.name+'-migrate'}}


{{project_rvm(
 'rake tmp:cache:clear --trace'
 '&& rake tmp:sessions:clear --trace'.format(cfg.data_root), state=cfg.name+'-clear')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{data.user}}
    - require:
       - cmd: {{cfg.name+'-plugins-migrate'}}
#}
