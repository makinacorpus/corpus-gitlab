{% import "makina-states/services/monitoring/circus/macros.jinja" as circus with context %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-projects.{{cfg.name}}.include.configs  

{{cfg.name}}-service:
  file.copy:
    - source: {{data.dir}}/lib/support/init.d/gitlab
    - name: /etc/init.d/gitlab
    - force: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: 750
  service.running:
    - name: gitlab
    - enable: true
    - watch:
      - file: {{cfg.name}}-service
      - mc_proxy: {{cfg.name}}-configs-after

