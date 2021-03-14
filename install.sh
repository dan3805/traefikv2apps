#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
updatesystem() {
if [[ $EUID -ne 0 ]]; then
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔  You Must Execute as a SUDO USER (with sudo) or as ROOT!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
exit 0
fi
while true; do
  if [[ ! -x "$(command -v docker)"  ]]; then exit 0;fi
  if [[ ! -x "$(command -v docker-compose)" ]]; then exit 0;fi
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
buildshow="ls /opt/apps/${section}"
build=$($buildshow | sed -e 's/.yml//g' )
if [[ $section == "mediaserver" ]]; then
    buildup=$($buildshow | sed -e 's/.yml//g' | sort -r | sed -e 's/embyintel//g' | sed -e 's/embynplex//g' | sed -e 's/plexnvidia//g' | sed -e 's/plexintel//g')
else
    buildup=$build
fi
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 App Installer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$buildup

[Z] Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


EOF
  read -p '↪️ Type app to install | Press [ENTER]: ' typed </dev/tty
  if [[ $typed == "exit" || $typed == "Exit" || $typed == "EXIT" || $typed == "z" || $typed == "Z" ]]; then exit; fi
  if [[ $typed == "" ]]; then install; fi
  current=$(ls /opt/apps/${section}/ | sed -e 's/.yml//g' | grep -qE "\<$typed\>" 1>/dev/null 2>&1 && echo true || echo false)
  if [[ $current == "true" && $typed != "" ]]; then run;fi

}
run() {
compose="compose/docker-compose.yml"
appfolder="/opt/apps"
basefolder="/opt/appdata"
 if [[ ! -d $basefolder/compose/ ]];then mkdir -p $basefolder/compose/; fi
 if [[ ! -x "$(command -v rsync)" ]]; then apt install rsync -yqq >/dev/null 2>&1; fi
 if [[ ${section} == "mediaserver" ]]; then
    if [[ ${typed} == "emby" || ${typed} == "plex" ]]; then
       IGPU=$(lshw -C video | grep -qE 'i915' && echo true || echo false)
       NGPU=$(lshw -C video | grep -qE 'nvidia' && echo true || echo false)
       if [[ $IGPU == "true" ]]; then
          rsync $appfolder/${section}/${typed}intel.yml $basefolder/$compose -aq --info=progress2 -hv
       elif [[ $NGPU == "true" ]]; then
          rsync $appfolder/${section}/${typed}nvidia.yml $basefolder/$compose -aq --info=progress2 -hv
       else
          rsync $appfolder/${section}/${typed}.yml $basefolder/$compose -aq --info=progress2 -hv
       fi
    fi
 else
   rsync $appfolder/${section}/${typed}.yml $basefolder/$compose -aq --info=progress2 -hv
fi
 if [[ ! -d $basefolder/${typed} ]]; then
    folder=$basefolder/${typed}
    for i in ${folder}; do
        mkdir -p $i
        find $i -exec chmod a=rx,u+w {} \;
        find $i -exec chown -hR 1000:1000 {} \;
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
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E "\<$typed\>")
if [[ $container != "" ]]; then
   docker stop $container 1>/dev/null 2>&1
   docker rm $container 1>/dev/null 2>&1
   docker image prune -af 1>/dev/null 2>&1
else
   docker image prune -af 1>/dev/null 2>&1
fi
if [[ ${section} == "mediaserver" && ${typed} == "plex" ]]; then plexclaim;fi
cd $basefolder/compose/ && docker-compose up -d --force-recreate 1>/dev/null 2>&1
if [[ ${section} == "mediaserver" && ${typed} == "plex" ]]; then plexprefrences;fi
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
plexprefrences() {
xmltest=$(command -v xmlstarlet)
if [[ ! -x $xmltest ]]; then apt install xmlstarlet -yqq; fi
DOMAIN=$(cat /etc/hosts | grep 127.0.0.1 | tail -n 1 | awk '{print $2}')
SERVERIP=$(ip addr show |grep 'inet '|grep -v 127.0.0.1 |awk '{print $2}'| cut -d/ -f1 | head -n1)
prefsecure=$(cat "/opt/appdata/plex/database/Library/Application Support/Plex Media Server/Preferences.xml" | grep -qE secureConnections && echo true || echo false)
prefconnection=$(cat "/opt/appdata/plex/database/Library/Application Support/Plex Media Server/Preferences.xml" | grep -qE customConnections && echo true || echo false)
if [[ $prefconnection == "false" || $prefsecure == "false" ]]; then
  echo "Adding resource Preferences.xml"
  replace="xmlstarlet"
  file="/opt/appdata/plex/database/Library/Application Support/Plex Media Server/Preferences.xml"
  for i in ${replace}; do
    $i ed -O --inplace --insert "/Preferences" --type attr -n "secureConnections" -v "1" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "GenerateChapterThumbBehavior" -v "never" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "LoudnessAnalysisBehavior" -v "never" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "MinutesAllowedPaused" -v "10" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "customConnections" -v "http://$SERVERIP:32400, http://plex.$DOMAIN:32400" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "AcceptedEULA" -v "1" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "DlnaEnabled" -v "p" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "ScannerLowPriority" -v "1" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "ManualPortMappingMode" -v "1" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "DlnaReportTimeline" -v "0" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "TranscoderTempDirectory" -v "/transcode" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "TranscoderThrottleBuffer" -v "200" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "TranscodeCountLimit" -v "4" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "autoEmptyTrash" -v "1" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "RelayEnabled" -v "0" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "DisableTLSv1_0" -v "1" $file
    $i ed -O --inplace --insert "/Preferences" --type attr -n "TranscoderH264BackgroundPreset" -v "faster" $file
    gpu="i915 nvidia"
    for ii in ${gpu}; do
       TDV=$(lshw -C video | grep -qE $ii && echo true || echo false)
       if [[ $TDV == "true" ]]; then
         $i ed -O --inplace --insert "/Preferences" --type attr -n "HardwareAcceleratedCodecs" -v "1" $file
       fi
    done
  done
fi
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'plex')
if [[ $container == "plex" ]]; then
   docker restart $container 1>/dev/null 2>&1
fi
}
backupcomposer() {
## run autocomposer when all is done
if [[ ! -d $basefolder/composebackup ]]; then mkdir -p $basefolder/composebackup/; fi
docker=$(docker ps -aq --format {{.Names}} )
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose $docker >>$basefolder/composebackup/docker-compose.yml
docker system prune -af
}




## notes !

# Subactions 2
#  >> downloader needs replacing after deploy for the configuration
#  >> restart docker then when downloader is found

#  >> run sqlite3 edit command

updatesystem