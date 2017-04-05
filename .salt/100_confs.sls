{% import "makina-states/_macros/h.jinja" as h with context %}
{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set project_root=cfg.project_root%}

include:
  - makina-projects.{{cfg.name}}.include.configs

{{cfg.name}}-setup-git:
  cmd.run:
    - name: |
            git config --global user.name "GitLab"
            git config --global user.email "git@{{data.domain}}"
            git config --global core.autocrlf input
            git config --global gc.auto 0
            git config --global repack.writeBitmaps true
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
    - force_reset: true
    - force_fetch: true
    - target: "{{data.dir}}"
    - user: "{{data.user}}"
    - rev: "{{data.version}}"
    - require:
      - cmd: {{cfg.name}}-download-gitlab
