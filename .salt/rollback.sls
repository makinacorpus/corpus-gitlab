


redmine-rollback-faileproject-dir:
  cmd.run:
    - name: |
            if [ -d "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project" ];then
              rsync -Aa --delete "/srv/projects/redmine/project/" "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project.failed/"
            fi;
    - user: redmine-user

redmine-rollback-project-dir:
  cmd.run:
    - name: |
            if [ -d "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project" ];then
              rsync -Aa --delete "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project/" "/srv/projects/redmine/project/"
            fi;
    - user: redmine-user
    - require:
      - cmd:  redmine-rollback-faileproject-dir
