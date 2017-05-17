{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}

{{cfg.name}}-pages-dirs:
  file.directory:
    - makedirs: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: "2751"
    - names:
      - "{{data.home}}/gitlab-pages"
    - require_in:
      - cmd: {{cfg.name}}-download-pages

{{cfg.name}}-download-pages:
  cmd.run:
    - name: |
        cd "{{data.pages_dir}}" || exit 0
        git stash
    - user: "{{data.user}}"
  mc_git.latest:
    - name: "{{data.pages_url}}"
    - target: "{{data.pages_dir}}"
    - user: "{{data.user}}"
    - rev: "{{data.pages_version}}"
    - require:
      - cmd: {{cfg.name}}-download-pages

{{cfg.name}}-download-pages-cmmi:
  cmd.run:
    - name: |
        set -e
        W="$(pwd)"
        export GOPATH=$PWD/go
        export PATH=$GOPATH/bin:$PATH
        if [ ! -e "$GOPATH/bin/godep" ];then
          go get github.com/tools/godep
        fi
        if [ ! -e "$GOPATH/src" ];then
          mkdir -p "$GOPATH/src"
        fi
        rm -f "$GOPATH/src/gitlab-pages"
        ln -s "${PWD}" "$GOPATH/src/gitlab-pages"
        cd "$GOPATH/src/gitlab-pages"
        go get
        make
    - cwd: "{{data.pages_dir}}"
    - runas: "{{data.user}}"
    - use_vt: true
    - require:
      - mc_git: {{cfg.name}}-download-pages
