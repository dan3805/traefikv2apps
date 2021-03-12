#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.

## notes ! 

## ls /opt/apps/${section} | sed -e 's/.yml//g' 
## ls -t /opt/apps/${section} | grep -v '/$' | sed -e 's/.yml//g'
## logic for nvidia|intel missing
## possibly solution find
## appfolder="/opt/appdata"
## if [[ ! -d "$appfolder/${typed}" ]]; then
##    folder="$appfolder/${typed}"
##    for i in ${folder}; do
##        mkdir -p /opt/appdata/$i
##        find $i -exec chmod a=rx,u+w {} \;
##        find $i -exec chown -hR 1000:1000 {}
##    done
## fi

Rsync or copie/mirror file /opt/appdata/compose/docker-compose.yml
>> When file exists remove or overwrite

# Subactions
  >> Plex need sub action for Claim
  #>> Check if /dev/dri is available 
  #>> check if nvidia-docker is running

Replace parts /opt/appdata/compose/docker-compose.yml
Check if file would working --config

## deploy
Join folder /opt/appdata/compose/
     Check of docker exist
     == no
     run docker-compose up -d {{ rebuild command }}
     == yes 
     Show Message with overwrite existing container

## end command
Check of Docker is running
== yes do nothing
== no try again 
 >> second  fail stop deploy 
    Show error 

# Subactions 2
  >> downloader needs replacing after deploy for the configuration
  >> restart docker then when downloader is found
  >> change values inside the Preferences.xml for Plex 
  >> run sqlite3 edit command

>>><<<
## run autocomposer when all is done
## mkdir -p /opt/appdata/composebackup/
## docker=$(docker ps -aq --format={{.Names}})
## docker run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose $docker >>/opt/appdata/composebackup/docker-compose.yml
## docker system prune -af
[X]  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose 
[X]  >> mirror to /opt/appdata/composebackup/
>>><<<
# Multi deploy *?* more as one docker at the same time *?* 
