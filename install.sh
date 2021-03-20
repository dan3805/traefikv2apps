#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
appstartup() {
if [[ $EUID -ne 0 ]]; then
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔  You Must Execute as a SUDO USER (with sudo) or as ROOT!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
exit 0
fi
while true; do
  if [[ ! -x $(command -v docker)  ]]; then exit 0;fi
  if [[ ! -x $(command -v docker-compose) ]]; then exit 0;fi
  interface
done
}
interface() {
buildshow=$(ls -1p /opt/apps/ | grep '/$' | sed 's/\/$//')
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      🚀 App Section Menu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$buildshow

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [ EXIT ] - Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  read -p '↘️  Type Section Name and Press [ENTER]: ' section </dev/tty

  if [[ $section == "exit" || $section == "Exit" || $section == "EXIT" || $section  == "z" || $section == "Z" ]];then exit;fi
  checksection=$(ls /opt/apps/ | grep -x $section)
  if [[ $section == "" ]] || [[ $checksection == "" ]];then clear && interface; fi
  if [[ $checksection == $section ]];then clear && install;fi
}
install() {
section=${section}
buildshow=$(ls -1p /opt/apps/${section}/compose/ | grep -v '/$' | sed -e 's/.yml//g' )

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 🚀 App Installer of ${section}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$buildshow

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [ EXIT or Z ] - Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

  read -p '↪️ Type App-Name to install and Press [ENTER]: ' typed </dev/tty

   if [[ $typed == "exit" || $typed == "Exit" || $typed == "EXIT" || $typed  == "z" || $typed == "Z" ]];then clear && interface;fi
   buildapp=$(ls /opt/apps/${section}/compose/ | sed -e 's/.yml//g' | grep -x $typed)
   if [[ $typed == "" ]] || [[ $buildapp == "" ]];then install;fi
   if [[ $buildapp == $typed ]];then runinstall;fi
}
runinstall() {
compose="compose/docker-compose.yml"
composeoverwrite="compose/docker-compose.override.yml"
appfolder="/opt/apps"
basefolder="/opt/appdata"
 if [[ ! -d $basefolder/compose/ ]];then $(command -v mkdir) -p $basefolder/compose/;fi
 if [[ -f $basefolder/$composeoverwrite ]];then $(command -v rm) -rf $basefolder/$composeoverwrite;fi
 if [[ ! -x $(command -v rsync) ]]; then $(command -v apt) install rsync -yqq >/dev/null 2>&1;fi
 if [[ ${section} == "mediaserver" ]]; then
     gpu="i915 nvidia"
     for i in ${gpu}; do
         TDV=$(lshw -C video | grep -qE $i && echo true || echo false)
         if [[ $TDV == "true" ]]; then $(command -v rsync) $appfolder/${section}/compose/gpu/$i.yml $basefolder/$composeoverwrite -aq --info=progress2 -hv;fi
     done
     if [[ $(uname) == "Darwin" ]]; then
        sed -i '' "s/<APP>/${typed}/g" $basefolder/$composeoverwrite
     else
        sed -i "s/<APP>/${typed}/g" $basefolder/$composeoverwrite
     fi
 else
   $(command -v rsync) $appfolder/${section}/compose/${typed}.yml $basefolder/$compose -aq --info=progress2 -hv
 fi
 if [[ ! -d $basefolder/${typed} ]]; then
    folder=$basefolder/${typed}
    for i in ${folder}; do
        $(command -v mkdir) -p $i
        $(command -v find) $i -exec $(command -v chmod) a=rx,u+w {} \;
        $(command -v find) $i -exec $(command -v chown) -hR 1000:1000 {} \;
    done
 fi
 ## change values inside docker-compose.yml
 DOMAIN=$(cat /etc/hosts | grep 127.0.0.1 | tail -n 1 | awk '{print $2}')
 if [[ $DOMAIN != "example.com" ]];then
    if [[ $(uname) == "Darwin" ]];then
       sed -i '' "s/example.com/$DOMAIN/g" $basefolder/$compose
    else
       sed -i "s/example.com/$DOMAIN/g" $basefolder/$compose
    fi
 fi
 if [[ ${section} == "mediaserver" ]]; then
    SERVERIP=$(ip addr show |grep 'inet '|grep -v 127.0.0.1 | awk '{print $2}'| cut -d/ -f1 | head -n1)
    if [[ $SERVERIP != "" ]]; then
       if [[ $(uname) == "Darwin" ]]; then
          sed -i '' "s/SERVERIP_ID/$SERVERIP/g" $basefolder/$compose
       else
          sed -i "s/SERVERIP_ID/$SERVERIP/g" $basefolder/$compose
      fi
    fi
 fi
 container=$($(command -v docker) ps -aq --format '{{.Names}}' | grep -x ${typed})
 if [[ $container != "" ]]; then
    docker="stop rm"
    for i in ${docker}; do
        $(command -v docker) $i $container 1>/dev/null 2>&1
    done
    $(command -v docker) image prune -af 1>/dev/null 2>&1
 else
    $(command -v docker) image prune -af 1>/dev/null 2>&1
 fi
 if [[ ${section} == "addons" && ${typed} == "vnstat" ]];then vnstatcheck;fi
 if [[ ${section} == "addons" && ${typed} == "autoscan" ]];then autoscancheck;fi
 if [[ ${section} == "mediaserver" && ${typed} == "plex" ]]; then plexclaim;fi
    cd $basefolder/compose/ && $(command -v docker-compose) up -d --force-recreate 1>/dev/null 2>&1
 if [[ ${section} == "mediaserver" || ${section} == "downloadclients" ]]; then subtasks;fi
 runningcheck=$($(command -v docker) ps -aq --format '{{.Names}} {{.State}}' | grep -x '${typed} running' | awk -F '{print $2' 1>/dev/null 2>&1 && echo true || echo false)
  if [[ $runningcheck == "true" ]];then
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ${typed} successfull deployed and working

  https://${typed}.$DOMAIN

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -p 'Confirm Info | PRESS [ENTER] ' typed </dev/tty
  clear
fi

}
vnstatcheck() {
if [[ ! -x $(command -v vnstat) ]];then $(command -v apt) install vnstat -yqq;fi
}
autoscancheck() {
if [[ ! -f $basefolder/${typed}/config.yml ]];then
   $(command -v rsync) $appfolder/${section}/compose/${typed}.config.yml $basefolder/${typed} -aq --info=progress2 -hv
   $(command -v bash) $appfolder/.subactions/compose/${typed}.sh
else
  tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ${typed} config found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      We found an existing config.yml for ${typed}
                no changes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -p 'Confirm Info | PRESS [ENTER] ' typed </dev/tty
  clear
fi
}
plexclaim() {
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 PLEX CLAIM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Please Claim the Plex Server

PLEX CLAIM

https://www.plex.tv/claim/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -ep "Enter your PLEX CLAIM CODE: " PLEXCLAIM

if [[ $PLEXCLAIM != "" ]]; then
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/$PLEX_CLAIM_ID/$PLEXCLAIM/g" $basefolder/$compose
   else
      sed -i "s/$PLEX_CLAIM_ID/$PLEXCLAIM/g" $basefolder/$compose
   fi
else
  echo "Plex Claim cannot be empty"
  plexclaim
fi
}
subtasks() {
if [[ -x $(command -v ansible) && -x $(command -v ansible-playbook) ]]; then
   if [[ -f $appfolder/.subactions/${typed}.yml ]];then $(command -v ansible-playbook) $appfolder/.subactions/${typed}.yml 1>/dev/null 2>&1;fi
fi
container=$($(command -v docker) ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -qE ${typed})
if [[ ${section} == "mediaserver" || ${section} == "downloadclients" ]]; then $(command -v docker) restart $container 1>/dev/null 2>&1;fi
backupcomposer
}
backupcomposer() {
if [[ ! -d $basefolder/composebackup ]]; then $(command -v mkdir) -p $basefolder/composebackup/;fi
docker=$($(command -v docker) ps -aq --format {{.Names}} )
$(command -v docker) run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose $docker >>$basefolder/composebackup/docker-compose.yml
$(command -v docker) system prune -af
}

appstartup