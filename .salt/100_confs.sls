{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}

{{cfg.name}}-setup-git:
  cmd.run:
    - name: |
            git config --global user.name "GitLab"
            git config --global user.email "git@{{data.domain}}"
            git config --global core.autocrlf input
    - user: {{data.user}}

{{cfg.name}}-download-gitlab:
  cmd.run:
    - name: git stash
    - user: "{{data.user}}"
    - cwd: "{{data.dir}}"
    - onlyif: test -e "{{data.dir}}/.git"
    - require:
      - cmd: {{cfg.name}}-setup-git
  mc_git.latest:
    - name: "{{data.url}}"
    - target: "{{data.dir}}"
    - user: "{{data.user}}"
    - rev: "{{data.version}}"
    - makedirs: true
    - require:
      - cmd: {{cfg.name}}-download-gitlab

{% for i in ['Gemfile.local',
             'config/environments/production.rb',
             'config/initializers/rack_attack.rb',
             'config/unicorn.rb',
             'config/resque.yml',
             'config/gitlab.yml',
             'config/database.yml'] %}
{{cfg.name}}-{{i}}:
  file.managed:
    - require:
      - cmd: {{cfg.name}}-setup-git
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/cfg/{{i}}
    - name:  {{data.dir}}/{{i}}
    - template: jinja
    - mode: 770
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        project: {{cfg.name}}
{% endfor %}
{% for i in [
             '/etc/logrotate.d/gitlab',
            ] %}
{{cfg.name}}-{{i}}:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/cfg/{{i}}
    - name:  {{i}}
    - template: jinja
    - mode: 770
    - user: "root"
    - group: "root"
    - defaults:
        project: {{cfg.name}}
{% endfor %}

{{cfg.name}}-profiled-rvm:
  file.managed:
    - makedirs: true
    - name: /etc/profile.d/z_rvm_gitlab.sh
    - contents: |
                #!/bin/sh
                groups="$(groups)"
                USERENV="$(echo $(whoami)_${$}|sed -e "s/\(-\)//g")"
                if [ "x$(env|grep -q "${USERENV}_RVM";echo ${?})" = "x1" ];then
                  if echo "${groups}"|grep -q rvm;then
                    . /usr/local/rvm/scripts/rvm
                    rvm --create use 'ruby-{{data.rversion}}@{{cfg.name}}'
                    export ${USERENV}_RVM="1"
                  fi
                fi
    - mode: 775
    - user: "root"
    - group: "root"

{{cfg.name}}-rvm-env:
  file.managed:
    - makedirs: true
    - name: "{{data.home}}/rvm_env.sh"
    - contents: |
                export GEM_HOME="/usr/local/rvm/gems/{{data.rversion}}@{{cfg.name}}"
                export IRBRC="/usr/local/rvm/rubies/ruby-{{data.rversion}}/.irbrc"
                export MY_RUBY_HOME="/usr/local/rvm/rubies/ruby-{{data.rversion}}"
                export PATH="/usr/local/rvm/gems/ruby-{{data.rversion}}@g{{cfg.name}}{{data.rversion}}@global/bin:/usr/local/rvm/rubies/ruby-{{data.rversion}}/bin:${PATH}"
                export rvm_ruby_string="ruby-{{data.rversion}}"
                export GEM_PATH="/usr/local/rvm/gems/ruby-{{data.rversion}}@{{cfg.name}}:/usr/local/rvm/gems/ruby-{{data.rversion}}@global"
                export RUBY_VERSION="ruby-{{data.rversion}}"
    - mode: 755
    - user: "root"
    - group: "root"

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
    - user: "root"
    - group: "root"

{{cfg.name}}-ruby-wrapper:
  file.managed:
    - makedirs: true
    - name: /usr/local/bin/ruby
    - contents: |
                #!/bin/sh
                groups="$(groups)"
                if echo "${groups}"|grep -q rvm;then
                  export GEM_HOME="/usr/local/rvm/gems/{{data.rversion}}@{{cfg.name}}"
                  export IRBRC="/usr/local/rvm/rubies/ruby-{{data.rversion}}/.irbrc"
                  export MY_RUBY_HOME="/usr/local/rvm/rubies/ruby-{{data.rversion}}"
                  export PATH="/usr/local/rvm/gems/ruby-{{data.rversion}}@g{{cfg.name}}{{data.rversion}}@global/bin:/usr/local/rvm/rubies/ruby-{{data.rversion}}/bin:${PATH}"
                  export rvm_ruby_string="ruby-{{data.rversion}}"
                  export GEM_PATH="/usr/local/rvm/gems/ruby-{{data.rversion}}@{{cfg.name}}:/usr/local/rvm/gems/ruby-{{data.rversion}}@global"
                  export RUBY_VERSION="ruby-{{data.rversion}}"
                fi
                ruby="$(which ruby 2>/dev/null)"
                if [ "x${ruby}" = "x/usr/local/bin/ruby" ];then
                  ruby="/usr/bin/ruby"
                fi
                exec "${ruby}" "${@}"
    - mode: 755
    - user: "root"
    - group: "root"
