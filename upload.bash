#!/bin/bash

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


# if there are no files available, dismount the drives and exit immediately
if [ -z "$LATEST" ]; then
  terminal-notifier -message "No new activites found in $LATEST" -title "No new activites" &> /dev/null || echo "No new activities found"
  diskutil unmount /Volumes/GARMIN
  diskutil unmount /Volumes/16GB\ SDHC
  exit
fi


# copy latest files to the download directory
# cp $LATEST $DLDIR


# upload to garmin
terminal-notifier -message "Uploading to Garmin..." -title "Uploading" &> /dev/null || echo "Uploading to Garmin..."
python /usr/local/bin/gupload.py $LATEST
terminal-notifier -message "Uploaded $LATEST --- Converting to HRM" -title "Upload Complete, HRM Converting..." &> /dev/null ||


# convert garmin data to Polar hrm data
sh $WORKINGDIR/g2p/bin/g2p.sh && (terminal-notifier -message "Completed fit -> hrm conversion" -title "FIT -> HRM" &> /dev/null || echo "Completed fit -> hrm conversion")


# unmount disks
diskutil unmount /Volumes/GARMIN
diskutil unmount /Volumes/16GB\ SDHC


# pop open polar uploader
java -jar HRMUploader.jar


# delete polar hrm file when polar uploader is closed
rm -rf $WORKINGDIR/hrm/*.hrm
