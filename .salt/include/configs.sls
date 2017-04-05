{% import "makina-states/_macros/h.jinja" as h with context %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set project_root=cfg.project_root%} 

{{cfg.name}}-configs-before:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-pre

{{cfg.name}}-configs-pre:
  mc_proxy.hook: []

{{cfg.name}}-configs-post:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-after

{% macro rmacro() %}
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-post
    - watch:
      - mc_proxy: {{cfg.name}}-configs-pre
{% endmacro %}
{{ h.deliver_config_files(
     data.get('configs', {}),
     dir='makina-projects/{0}/files/cfg/'.format(cfg.name),
     mode='640',
     user=data.user,
     group=cfg.group,
     target_prefix=data.dir+"/",
     after_macro=rmacro, prefix=cfg.name+'-config-conf',
     project=cfg.name,
     cfg=cfg.name)}}

{{cfg.name}}-configs-after:
  mc_proxy.hook: []



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
