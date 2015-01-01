

redmine-sav-project-dir:
  cmd.run:
    - name: |
            if [ ! -d "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project" ];then
              mkdir -p "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project";
            fi;
            rsync -Aa --delete "/srv/projects/redmine/project/" "/srv/projects/redmine/archives/2014-10-08_23_15-39_f68b32b5-b0d9-4293-bd9d-0e063a65b622/project/"
    - user: root
