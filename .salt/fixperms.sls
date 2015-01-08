
{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
{# export macro to callees #}
{% set ugs = salt['mc_usergroup.settings']() %}
{% set locs = salt['mc_locations.settings']() %}
{% set cfg = opts['ms_project'] %}
{{cfg.name}}-restricted-perms:
  file.managed:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - mode: 750
    - user: {% if not cfg.no_user%}{{cfg.user}}{% else -%}root{% endif %}
    - group: {{cfg.group}}
    - contents: |
            #!/usr/bin/env bash
            if [ -e "{{cfg.pillar_root}}" ];then
            "{{locs.resetperms}}" "${@}" \
              --dmode '0770' --fmode '0770' \
              --user root --group "{{ugs.group}}" \
              --users root \
              --groups "{{ugs.group}}" \
              --paths "{{cfg.pillar_root}}";
            fi
            if [ -e "{{cfg.project_root}}" ];then
              "{{locs.resetperms}}" "${@}" \
                --dmode '0771' --fmode '0771'  \
                --paths "{{cfg.project_root}}" \
                --users www-data\
                --users {{cfg.data.user}}\
                --users {{cfg.user}}:r-x\
                --groups {{cfg.group}}\
                --user  {{cfg.user}}\
                --group {{cfg.group}};
              "{{locs.resetperms}}" "${@}" \
                --no-recursive\
                --dmode '0771' --fmode '0771'\
                --paths "{{cfg.data_root}}" \
                --users "{{cfg.data.user}}:r-x" \
                --users www-data \
                --user  {{cfg.user}} \
                --group {{cfg.group}};
              "{{locs.resetperms}}" "${@}" \
                --dmode '0771' --fmode '0771'  \
                --paths "{{data.repos_path}}" \
                --paths "{{data.satellites_dir}}" \
                --paths "{{data.dir}}" \
                -e ".*\.ssh.*" \
                --users www-data\
                --users {{cfg.data.user}} \
                --users {{cfg.user}}\
                --groups {{cfg.group}} \
                --user  {{data.user}}\
                --group {{data.group}};
              setfacl -b -k "{{data.home}}";
              # group == data.user is normal here
              "{{locs.resetperms}}"\
                --dmode '0751' --fmode '0751'  \
                --no-recursive\
                --paths "{{data.home}}" \
                --users www-data\
                --users {{cfg.data.user}} \
                --users {{cfg.user}}\
                --user  {{data.user}}\
                --group {{data.user}}\
                --groups {{cfg.group}}:r-x\
                --groups {{data.group}}:r-x;
              "{{locs.resetperms}}" "${@}" \
                --no-recursive -o\
                --dmode '0555' --fmode '0644'  \
                -e ".*\.ssh.*" \
                --paths "{{cfg.project_root}}" \
                --paths "{{cfg.project_dir}}" \
                --paths "{{cfg.project_dir}}"/.. \
                --paths "{{cfg.project_dir}}"/../.. \
                --users "{{cfg.data.user}}" \
                --users www-data;
              if [ ! -e "{{cfg.data.home}}/.ssh" ];then
                mkdir -pv "{{cfg.data.home}}/.ssh"
              fi
              "{{locs.resetperms}}"\
               --dmode '0700' --fmode '0700' \
               --paths "{{cfg.data.home}}/.ssh";
              chmod -Rfv 700 "{{cfg.data.home}}/.ssh"
              chown -Rfv "{{data.user}}:{{data.user}}" "{{cfg.data.home}}/.ssh"
              {% if data.sshgroup %}
              gpasswd -a {{data.user}} {{data.sshgroup}}
              {% endif %}
            fi
  cmd.run:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - cwd: {{cfg.project_root}}
    - user: root
    - watch:
      - file: {{cfg.name}}-restricted-perms

