{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}

{{cfg.name}}-download-wh:
  cmd.run:
    - name: |
        cd "{{data.workhorse_dir}}/.git/.." || exit 0
        git stash
    - user: "{{data.user}}"
  mc_git.latest:
    - name: "{{data.workhorse_url}}"
    - target: "{{data.workhorse_dir}}"
    - user: "{{data.user}}"
    - rev: "{{data.workhorse_version}}"
    - require:
      - cmd: {{cfg.name}}-download-wh 

{{cfg.name}}-download-wh-cmmi:
  cmd.run: 
    - name: |
        make 
    - cwd: "{{data.workhorse_dir}}"
    - use_vt: true
    - require:
      - mc_git: {{cfg.name}}-download-wh  
