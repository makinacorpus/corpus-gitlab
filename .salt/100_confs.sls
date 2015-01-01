{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% for i in ['Gemfile.local',
             'config/environments/production.rb',
             'config/initializers/rack_attack.rb',
             'config/unicorn.rb',
             'config/resque.yml',
             'config/gitlab.yml',
             'config/database.yml'] %}
{{cfg.name}}-{{i}}:
  file.managed:
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
