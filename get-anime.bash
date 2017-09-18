#!/bin/bash
# Awatsuki DPS - Automated Anime Downloader
crunchyroll() {
#Get CrunchyRoll Series
echo "= CrunchyRoll ==========================================="
while read -r show; do
  if [ ! $show = \#* ]; then
    series=$(echo $show | awk -F '[;]' '{print $1}')
	type=$(echo $show | awk -F '[;]' '{print $2}')
	if [ ${type} = "a" ]; then ${exec_crunchy} -u ${cr_user} -p ${cr_pass} -o ${anime} ${cr_base}/${series}
	elif [ ${type} = "d" ]; then ${exec_crunchy} -u ${cr_user} -p ${cr_pass} -o ${drama} ${cr_base}/${series}
	fi
	
	echo "========================================================"
	sleep 30
  fi
done < "${1}"
}
funimation() {
#Get Funimation Series
echo "= FunimationNow ========================================="
echo "Authenticating....."
node ${exec_funidl} --mail ${funi_user} --pass ${funi_pass}
while read -r show; do
  if [ ! $show = \#* ]; then
    echo "Preparing data....."
    show_id=$(echo $show | awk -F '[;]' '{print $1}') # Parse Show ID Number
	# Get Show ID buy using : funi --search "Show Name"
    lang=$(echo $show | awk -F '[;]' '{print $2}') # Parse Show Language - en or jp
    quality=$(echo $show | awk -F '[;]' '{print $3}') # Quality of Video - 1080p, 720p, etc.
    series_meta=$(node ${exec_funidl} -s ${show_id} | tail -2 | head -1) # Get Latest Episode
    series_name=$(echo ${series_meta:6} | awk -F '[-]' '{print $1}' |  while read spo; do echo ${spo}; done) # Get Show Full Name
    last_epid=${series_meta:1:4} # Get the latest episodes number
    last_local_ep="00" # Default Local Episode Number for if there being none alrady downloaded (Note how its a string and not a int)
    if [ ! -d "${anime}${series_name}/" ]; then mkdir -p "${anime}${series_name}/" ;fi # Create folder if does not exsist
    if [ ! $(find "${anime}${series_name}/[Funimation]"* -printf "%f\n" | wc -l) = 0 ]; then last_local_ep=$(find "${anime}${series_name}/[Funimation]"* -printf "%f\n" | tail -1| awk -F '[-]' '{print $2}' | while read spo; do echo ${spo:0:2}; done); fi
	# Determin if any episods exsist on data storage, if so then get the last episodes number (Could be a problem later but a wc would not be any safer)
    echo "$series_name: [$show_id]"
    echo "Latest Episode: [${last_epid#0}] - Current Episode: [${last_local_ep#0}]"

    while [ ! ${last_epid} -eq ${last_local_ep} ]
    do
      echo "Downloading episode [${last_local_ep#0+1}] in [${lang}@${quality}]....."
      last_local_ep=$(echo ${last_local_ep#0}+1 | bc)
      if [ ${lang} = "en" ]; then node ${exec_funidl} -q ${quality} --nosubs --mkv -s ${show_id} --sel ${last_local_ep}
      elif [ ${lang} = "jp" ]; then node ${exec_funidl} -q ${quality} --mkv --mks --sub -s ${show_id} --sel ${last_local_ep}
      fi
      echo "Moving downloads....."
      mv ${tmp}*.mkv "${anime}${series_name}/"
    done
	echo "========================================================"
    sleep 30
  fi
done < "${1}"
}
source ./get-anime.config
while getopts "rcfC:F:" opt; do 
  case $opt in
    r) crunchyroll "${cr_watch}"; funimation "${funi_watch}";;
	c) crunchyroll "${cr_watch}";;
	f) funimation "${funi_watch}";;
  	C) crunchyroll "${OPTARG}";;
	F) funimation "${OPTARG}";;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; exit 1;;
  esac
done