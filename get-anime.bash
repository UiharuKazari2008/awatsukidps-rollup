#!/bin/bash
# Awatsuki DPS - Automated Anime Downloader

# CrunchyRoll
cr_watch="watchlist.cr"
cr_user="user@email.com"
cr_pass="password"
cr_base="http://www.crunchyroll.com"
#FunimationNow
funi_watch="watchlist.funi"
funi_user="user@email.com"
funi_pass="password"
#Storage
stor="/dir/"
tmp=""

#Get CrunchyRoll Series
while read -r show; do
  [[ $line = \#* ]] && continue
  crunchy -u ${cr_user} -p ${cr_pass} -o ${stor} ${cr_base}/${show}
  sleep 30
done < "$cr_watch"

#Get Funimation Series
echo "= FunimationNow ========================================="
echo "Authenticating....."
#cd /opt/funimation-downloader-nx
/usr/bin/nodejs /opt/funimation-downloader-nx/scripts/funidl.js --mail ${funi_user} --pass ${funi_pass}
while read -r show; do
  [[ $show = \#* ]] && continue
  echo "Preparing data....."
  show_id=$(echo $show | awk -F '[;]' '{print $1}')
  lang=$(echo $show | awk -F '[;]' '{print $2}')
  series_meta=$(/usr/bin/nodejs /opt/funimation-downloader-nx/scripts/funidl.js -s ${show_id} | tail -2 | head -1)
  series_name=$(echo ${series_meta:6} | awk -F '[-]' '{print $1}' |  while read spo; do echo ${spo}; done)
  last_epid=${series_meta:1:4}
  last_local_ep="00"
  if [ ! -d "${stor}${series_name}/" ]; then mkdir -p "${stor}${series_name}/" ;fi
  if [ ! $(find "${stor}${series_name}/[Funimation]"* -printf "%f\n" | wc -l) = 0 ]; then last_local_ep=$(find "${stor}${series_name}/[Funimation]"* -printf "%f\n" | tail -1| awk -F '[-]' '{print $2}' | while read spo; do echo ${spo:0:2}; done); fi
  echo "$series_name [$show_id]"
  echo "Latest Episode: $last_epid - Current Episode: $last_local_ep"

  while [ ! ${last_epid} -eq ${last_local_ep} ]
  do
    echo "Downloading episode $last_local_ep in $lang....."
    last_local_ep=$(echo ${last_local_ep#0}+1 | bc)
    if [ ${lang} = "en" ]; then /usr/bin/nodejs /opt/funimation-downloader-nx/scripts/funidl.js -q 1080p --nosubs --mkv -s ${show_id} --sel ${last_local_ep}
    elif [ ${lang} = "jp" ]; then /usr/bin/nodejs /opt/funimation-downloader-nx/scripts/funidl.js -q 1080p --mkv --mks --sub -s ${show_id} --sel ${last_local_ep}
    fi
    echo "Moving video....."
    mv /mnt/tmp/funi/videos/*.mkv "${stor}${series_name}/"
  done


  sleep 30
done < "$funi_watch"
