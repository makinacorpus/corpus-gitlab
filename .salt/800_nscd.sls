
/etc/cron.d/nscd:
  file.managed:
    - contents: |
                MAILTO=""
                */2 * * * * root service nscd stop >/dev/null 2>&1
    - user: root
    - group: root
    - mode: 750
