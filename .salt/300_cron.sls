{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm.sls" as rvm with context %}

{{cfg.name}}-rvm-wrapper:
  file.managed:
    - name: /etc/cron.d/ldapredmine{{cfg.name}}
    - mode: 750
    - user: root
    - group: root
    - contents: |
                #!/usr/bin/env bash
                MAILTO=root
                */10 * * * * {{cfg.user}} cd {{cfg.project_root}}/redmine && ../rvm.sh rake -f Rakefile --silent redmine:plugins:ldap_sync:sync_users RAILS_ENV=production 2>&- 1>/dev/null


