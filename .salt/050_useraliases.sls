{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}

{% for u in data.get('git_user_aliases', []) %}
{% for i in '/etc/passwd', '/etc/shadow' %}
{{cfg.name}}-{{u}}-{{i}}:
  cmd.run:
    - name: |
            line="$(grep "^{{data.user}}:" "{{i}}"|sed -e "s/^{{data.user}}:/{{u}}:/g")"
            echo "${line}">>{{i}}
    - user: root
    - onlyif: 'test "x$(egrep "^{{u}}:" "{{i}}";echo ${?})" = "x1" && test "x$(egrep -q "^{{data.user}}:" "{{i}}";echo ${?})" = "x0"'
{% endfor %}
{% endfor %}
