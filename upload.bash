#!/bin/bash

# notification wrapper
function notify() {
  osascript -e "display notification \"$2\" with title \"$1\""
}

# If there's no garmin device connected...
if [ ! -d "/Volumes/GARMIN" ]; then
	echo "--------------------------------------"
	echo ""
	echo "Please Connect your Garmin device to your computer"
	echo ""
	echo "--------------------------------------"
	exit
fi

# gets current directory of bash script
pushd `dirname $0` > /dev/null
export WORKINGDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# load settings
source $WORKINGDIR/.settings
source $WORKINGDIR/.usersettings
sleep 1


# find which device is connected
for i in "${DEVICEDIRS[@]}"
do
  if [ -d $i ]; then
    GARMINDIR=$i
  fi
done

# find files in last x time, configurable in .settings
LATEST=`find $GARMINDIR -type f -mtime -$TIME -print -iname "$PATTERN"`

# if there are no new activities, dismount the drives and exit immediately
if [ -z "$LATEST" ]; then
  notify "No new activites" "No new activites found in $LATEST" &> /dev/null || echo "No new activities found"
  diskutil unmount /Volumes/GARMIN
  diskutil unmount /Volumes/16GB\ SDHC
  exit
fi

# copy latest files to the download directory
cp $LATEST $DLDIR

# upload to garmin
notify "FIT -> Garmin" "Uploading data to Garmin..." &> /dev/null || echo "Uploading to Garmin..."
python GcpUploader/gupload.py $LATEST

# unmount disks
diskutil unmount /Volumes/GARMIN
diskutil unmount /Volumes/16GB\ SDHC

# if USEPOLAR is set to false by the user, exit after uploading to Garmin
if ! $USEPOLAR; then
  exit
fi

# convert garmin data to Polar hrm data
sh $WORKINGDIR/GarminToPolar/bin/g2p.sh && (notify "HRM -> Polar" "Upload Complete. Polar Uploader launching" &> /dev/null || echo "Completed fit -> hrm conversion")

# pop open polar uploader
java -jar HRMUploader.jar

# if the user sets this variable to false, keep the HRM data after uploading to Polar
if $DELETEHRMAFTERUPLOAD; then
  rm -rf $WORKINGDIR/hrm/*.hrm
fi
