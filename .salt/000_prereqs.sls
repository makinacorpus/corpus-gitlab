{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
include:
  - makina-states.services.http.nginx
  - makina-states.services.db.redis
  - makina-states.services.db.postgresql.client
  - makina-states.localsettings.rvm
  - makina-states.localsettings.nodejs
  - makina-states.localsettings.golang
  - makina-states.localsettings.users.hooks

{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}
{% import "makina-states/localsettings/users/init.sls" as users with context %}
{{users.create_user(data.user, {'home': data.home})}}
{{rvm.install_ruby(data.rversion)}}

prepreqs-{{cfg.name}}:
  pkg.installed:
    - pkgs:
      - unzip
      - imagemagick
      - cmake
      - libmagick++-dev
      - libicu-dev
      - xsltproc
      - postgresql-client
      - libpq-dev
      - curl
      - uuid-dev
      - e2fslibs-dev
      - sqlite3
      - libmysqlclient-dev
      - libldap2-dev
      - libsqlite3-dev
      - mysql-client
      - apache2-utils
      - autoconf
      - automake
      - build-essential
      - bzip2
      - gettext
      - git
      - groff
      - libbz2-dev
      - libcurl4-openssl-dev
      - libdb-dev
      - libgdbm-dev
      - libreadline-dev
      - libfreetype6-dev
      - libsigc++-2.0-dev
      - libsqlite0-dev
      - libsqlite3-dev
      - libtiff5
      - libtiff5-dev
      - libwebp5
      - libwebp-dev
      - libssl-dev
      - libtool
      - libxml2-dev
      - libxslt1-dev
      - libopenjpeg-dev
      - libopenjpeg2
      - m4
      - man-db
      - pkg-config
      - poppler-utils
      - python-dev
      - python-imaging
      - python-setuptools
      - tcl8.4
      - tcl8.4-dev
      - tcl8.5
      - tcl8.5-dev
      - tk8.5-dev
      - zlib1g-dev
      - imagemagick
      - ruby-rmagick
      - nodejs
      # syntax hilight
      - python-docutils
      - python3-docutils

{% set dirs = [
  (cfg.data.home, '2771'),
  (cfg.data.home + '/.ssh', '2751'),
  (cfg.data.repos_path, '2771'),
  (cfg.data.satellites_dir, '2771')]
%}
{% for d, m in dirs %}
{{cfg.name}}-dirs-{{d}}:
  file.directory:
    - makedirs: true
    - user: {{data.user}}
    - group: {{cfg.group}}
    - mode: "{{m}}"
    - watch:
      - pkg: prepreqs-{{cfg.name}}
    - name: "{{d}}"
{% endfor %}
