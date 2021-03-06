
{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
{# export macro to callees #}
{% set locs = salt['mc_locations.settings']() %}
{{cfg.name}}-restricted-perms:
  file.managed:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - mode: 750
    - user: {% if not cfg.no_user%}{{cfg.user}}{% else -%}root{% endif %}
    - group: {{cfg.group}}
    - contents: |
            #!/usr/bin/env bash
            # hack to be sure that nginx is in www-data
            # in most cases
            datagroup="{{cfg.group}}"
            groupadd -r $datagroup 2>/dev/null || /bin/true
            users="nginx www-data {{data.user}} {{cfg.user}}"
            for i in $users;do
              gpasswd -a $i $datagroup 2>/dev/null || /bin/true
            done
            # be sure to remove POSIX acls support
            "{{locs.resetperms}}" -q --no-acls\
              --user root --group "$datagroup" \
              --dmode '0770' --fmode '0770' \
              --paths "{{cfg.pillar_root}}";
            find -H \
              "{{cfg.project_root}}" \
              "{{cfg.data_root}}" \
              \(\
                \(     -type f -and \( -not -user {{cfg.user}} -or -not -group $datagroup                      \) \)\
                -or \( -type d -and \( -not -user {{cfg.user}} -or -not -group $datagroup -or -not -perm -2000 \) \)\
              \)\
              | grep -v "{{data.home}}" \
              | while read i;do
                if [ ! -h "${i}" ];then
                  if [ -d "${i}" ];then
                    chmod g-s "${i}"
                    chown {{cfg.user}}:$datagroup "${i}"
                    chmod g+s "${i}"
                  elif [ -f "${i}" ];then
                    chown {{cfg.user}}:$datagroup "${i}"
                  fi
                fi
            done
            if [ ! -e "{{cfg.data.home}}/.ssh" ];then
              mkdir -pv "{{cfg.data.home}}/.ssh"
            fi
            find -H \
              "{{data.repos_path}}" \
              "{{data.home}}" \
              \(\
                \(     -type f -and \( -not -user {{data.user}} -or -not -group $datagroup                      \) \)\
                -or \( -type d -and \( -not -user {{data.user}} -or -not -group $datagroup -or -not -perm -2000 \) \)\
              \)\
              |\
              while read i;do
                if [ ! -h "${i}" ];then
                  if [ -d "${i}" ];then
                    chmod g-s "${i}"
                    chown {{data.user}}:$datagroup "${i}"
                    chmod g+s "${i}"
                  elif [ -f "${i}" ];then
                    chown {{data.user}}:$datagroup "${i}"
                  fi
                fi
            done
            chmod 2750 "{{data.home}}"
            "{{locs.resetperms}}" -q --no-acls --no-recursive\
              --user root --group root --dmode '0555' --fmode '0555' \
              --paths "{{cfg.project_dir}}/global-reset-perms.sh" \
              --paths "{{cfg.project_root}}"/.. \
              --paths "{{cfg.project_root}}"/../..;
            {% if data.sshgroup %}
            gpasswd -a {{data.user}} {{data.sshgroup}}
            {% endif %}
            chown -Rf {{data.user}} "{{cfg.data.home}}/.ssh"
            chmod -R g-s "{{cfg.data.home}}/.ssh" 
            chmod -R 0700 "{{cfg.data.home}}/.ssh" 
  cmd.run:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - cwd: {{cfg.project_root}}
    - user: root
    - watch:
      - file: {{cfg.name}}-restricted-perms


{{cfg.name}}-fixperms:
{% if cfg.data.get('fixperms_cron_periodicity', '') %}
  file.managed:
    - name: /etc/cron.d/{{cfg.name.replace('.', '_')}}-fixperms
    - user: root
    - mode: 744
    - contents: |
                {{cfg.data.fixperms_cron_periodicity}} root {{cfg.project_dir}}/global-reset-perms.sh >/dev/null 2>&1
{%else%}
  file.absent:
    - name: /etc/cron.d/{{cfg.name.replace('.', '_')}}-fixperms
{% endif %}
    - require:
      - file: {{cfg.name}}-restricted-perms
