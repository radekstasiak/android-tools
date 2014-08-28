#!/bin/bash

# 2014
# Radek Stasiak
# radek.stasiak@gmail.com  
# script for android phones to automatically transfer photos/movies, according to provided date 
# script reguires symlink to android-sdk adb, created under /usr/bin/adb

usage()
{
	cat <<EOF
	usage: 

	This script allows to transfer photos/movies from Android phone to your local machine. 
	Which media should be transfered is defined by date, which defines oldest photo/movie to copy.

	OPTIONS:

	-h displays this menu

	Required:
	-d date in format YYYY-MM-DD of oldest media you wantt to transfer

	Optional:

	-a adb location, by default it's adb symlink in /usr/bin/
	-r remote directory on Android, where media are stored, by default it's /sdcard/DCIM/100ANDRO/ 
	-l local directory, where media will be transfered, by default it's ./android_media/ in script's workspace
	-t file type you want to transfer e.g. mp4, jpg etc., by default it transfers all kinds of file in remote directory
EOF
}

compare_date=
tmp_file=/tmp/tmp_file
src_location=/sdcard/DCIM/100ANDRO/
dest_location=$PWD/android_media/
adb_location=adb
file_type=
touch $tmp_file

while getopts "h:d:a:r:l:t:" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		d)
			compare_date=$OPTARG
			;;
		a)
			adb_location=$OPTARG
			;;
		r)
			src_location=$OPTARG
			;;
		l)
			dest_location=$OPTARG
			;;
		t)
			file_type=$OPTARG
			;;
		?)
			usage
			exit
			;;
	esac
done

if [[ -z $compare_date ]]
then
	usage
	exit 1
fi		
	
###############################################################################
#######TODO - regex below should work (it does in regex tests' websites)#######
###regex='^(19|20)\d\d[-/.](0[1-9]|1[012])[-/.](0[1-9]|[12][0-9]|3[01])$'######
###############################################################################

if ! [[ "$compare_date" =~ ^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$ ]]; 
then
	usage
	exit 1
fi


echo "adb: " $adb_location
echo "Boundary date: " $compare_date
echo "Remote location: " $src_location
echo "Destination location: " $dest_location

if [[ -z $file_type ]]
	then
		echo "File type: all"
	else
		echo "File type:" $file_type
	fi
compare_date=`echo $compare_date| tr -d '-'`

if ! [[ -e $dest_location ]]
	then
		echo "Creating output directory: " $dest_location
		mkdir -p $dest_location
	fi

echo "Obtaining file list ..."
$adb_location shell "

if [ -e $src_location ]; then ls  -al $src_location; fi 


" > $tmp_file

while read line
do

	name=`echo $line | cut -d' ' -f7` 
	file_date=`echo $line | cut -d' ' -f5 | tr -d '-'`

	if [[ "$name" == *$file_type* ]]
	then
		if [ $file_date -ge $compare_date ]
			then
			name=`echo $name | tr -d '\r'`
			echo "Copying "$src_location$name" to " $dest_location/$name" ..."
			$adb_location pull $src_location$name $dest_location/$name 
		fi
	fi


done < $tmp_file

echo "Cleaning ..."
rm -rf $tmp_file

