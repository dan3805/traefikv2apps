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
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 App Installer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] Mediamanager
[2] Mediaserver
[3] Download Clients
[4] System
[5] Addons

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Z] - Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  read -p '↘️  Type Number | Press [ENTER]: ' typed </dev/tty
  case $typed in
  1) mediamanager && interface ;;
  2) mediaserver && interface ;;
  3) downloadclients && interface ;;
  4) system && interface ;;
  5) addons && interface ;;
  z) exit 0 ;;
  Z) exit 0 ;;
  *) interface ;;
  esac
}
## section part
mediamanager() {
section=mediamanager
install
}
mediaserver() {
section=mediaserver
install
}
downloadclients() {
section=downloadclients
install
}
system() {
section=system
install
}
addons() {
section=addons
install
}

install() {
buildshow="ls -p /opt/apps/${section}/compose/"
build=$($buildshow | grep -v '/$' | sed -e 's/.yml//g' )

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 App Installer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$build

[Z] Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


EOF

  read -p '↪️ Type app to install | Press [ENTER]: ' typed </dev/tty

  if [ $typed == "z" && ${section} != "0" ] || [ $typed == "Z" && ${section} != "0" ]]; then exit;else interface;fi
  if [[ $typed == "" ]]; then install; fi
  current=$($build | grep -qE ${typed} 1>/dev/null 2>&1 && echo true || echo false)
  if [[ $current == "false" ]]; then install;fi
  if [[ $current == "true" ]]; then run;fi

}
run() {
compose="compose/docker-compose.yml"
composeoverwrite="compose/docker-compose.override.yml"
appfolder="/opt/apps"
basefolder="/opt/appdata"
 if [[ -f $basefolder/$composeoverwrite ]];then $(command -v rm) -rf $basefolder/$composeoverwrite;fi
 if [[ ! -d $basefolder/compose/ ]];then $(command -v mkdir) -p $basefolder/compose/;fi
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
if [[ $DOMAIN != "example.com" ]]; then
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/example.com/$DOMAIN/g" $basefolder/$compose
   else
      sed -i "s/example.com/$DOMAIN/g" $basefolder/$compose
   fi
fi
if [[ ${section} == "mediaserver" && ${typed} == "plex" ]]; then
   SERVERIP=$(ip addr show |grep 'inet '|grep -v 127.0.0.1 |awk '{print $2}'| cut -d/ -f1 | head -n1)
   if [[ $SERVERIP != "" ]]; then
      if [[ $(uname) == "Darwin" ]]; then
         sed -i '' "s/SERVERIP_ID/$SERVERIP/g" $basefolder/$compose
      else
         sed -i "s/SERVERIP_ID/$SERVERIP/g" $basefolder/$compose
     fi
   fi
fi
TZTEST=$(command -v timedatectl && echo true || echo false)
TZONE=$(timedatectl | grep "Time zone:" | awk '{print $3}')
if [[ $TZTEST != "false" ]]; then
   if [[ $TZONE != "" ]]; then
      if [[ $(uname) == "Darwin" ]]; then
         sed -i '' "s/UTC/$TZONE/g" $basefolder/$compose
      else
         sed -i "s/UTC/$TZONE/g" $basefolder/$compose
      fi
   fi
fi
container=$($(command -v docker) ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E "\<$typed\>")
if [[ $container != "" ]]; then
   docker="stop rm"
   for i in ${docker}; do
       $(command -v docker) $i $container 1>/dev/null 2>&1
   done
   $(command -v docker) image prune -af 1>/dev/null 2>&1
else
   $(command -v docker) image prune -af 1>/dev/null 2>&1
fi
if [[ ${section} == "mediaserver" && ${typed} == "plex" ]]; then plexclaim;fi
   cd $basefolder/compose/ && $(command -v docker-compose) up -d --force-recreate 1>/dev/null 2>&1
if [[ ${section} == "mediaserver" || ${section} == "downloadclients" ]]; then subtasks;fi
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
   if [[ -f $appfolder/subactions/${typed}.yml ]];then $(command -v ansible-playbook) $appfolder/subactions/${typed}.yml;fi
fi
#if [[ ${section} == "mediaserver" && ${typed} == "plex" || ${typed} == "emby" ]]; then $(command -v bash) $appfolder/subactions/${typed}.sh;fi
container=$($(command -v docker) ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -qE "\<$typed\>")
if [[ ${section} == "mediaserver" || ${section} == "downloadclients" ]]; then $(command -v docker) restart $container 1>/dev/null 2>&1;fi
backupcomposer
}
backupcomposer() {
## run autocomposer when all is done
if [[ ! -d $basefolder/composebackup ]]; then $(command -v mkdir) -p $basefolder/composebackup/;fi
docker=$($(command -v docker) ps -aq --format {{.Names}} )
$(command -v docker) run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose $docker >>$basefolder/composebackup/docker-compose.yml
$(command -v docker) system prune -af
}

appstartup
