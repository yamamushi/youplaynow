#!/bin/bash
#
# youplaynow
# 
# youplaynow is a wrapper for youtube-dl, which can be found at https://github.com/rg3/youtube-dl/
# the purpose of this tool is to allow for easier archiving of youtube audio playlists 
#
# Created August, 2018
# by Yamamushi 

Version="0.1"
YTDL="$(which youtube-dl)"
export ORGANIZE="true"

read -r -d '' USAGE << EOM
NAME: 
	youplaynow - A wrapper for ytdl to simplify the archiving of audio playlists

USAGE: 
	$0 

VERSION:
	$Version

GLOBAL OPTIONS:

	--help, -h 		show help
	--playlist, -p 		the playlist url to download
	--directory, -d 	the path where to store the downloads (defaults to cwd)
	--noorg 		disables the auto-organization of downloaded files 
	
	--version, -V 		print the version
EOM

set -e 
shopt -s nocasematch


if [ -z "$1" ]; then
	echo "$USAGE"
	exit 1
fi

if [ -z $YTDL ]; then
	echo "Could not find youtube-dl"
	exit 1
fi 


while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -V | --version) 
	echo $Version
	exit
	;;
	-h | --help)
	shift; echo "$USAGE"
	;;
	-p | --playlist)
	shift; PLAYLISTURL="$1"
	;;
	-d | --directory)
	shift; export DIR="$1"
	;;
	--noorg)
	shift; export ORGANIZE="false"
	;; 
esac; shift; done 
if [[ "$1" == "--" ]]; then shift; fi 

if [ -z $PLAYLISTURL ]; then
	echo "Error: a playlist url must be provided, see help for more usage"
	exit 1
fi 

if [ -z $DIR ]; then 
	export DIR="./"
fi 

if [ ! -d $DIR ]; then 
	mkdir -p $DIR
fi 

echo "Changing directory to $DIR"
cd $DIR 

getartist()
{
	sep="-"
	if [[ $@ == *"@"* ]]; then
		sep="@"
	elif [[ $@ == *"_"* ]]; then
		sep="_"
	elif [[ $@ == *"-"* ]]; then
		sep="-"
	fi  
	artist=$(echo $@ | sed -e "s/.mp3$//" | cut -f1 -d"$sep" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	echo $artist 
}
export -f getartist

gettitle()
{
	sep="-"
	if [[ $@ == *"@"* ]]; then
		sep="@"
	elif [[ $@ == *"_"* ]]; then
		sep="_"
	elif [[ $@ == *"-"* ]]; then
		sep="-"
	fi 
	title=$(echo $@ | sed -e "s/.mp3$//" | cut -f2- -d"$sep" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') 
	echo $title
}
export -f gettitle

getimagepath()
{
	imagepath=$(echo $@ | sed -e "s/.mp3$/.jpg/") 
	echo $imagepath
}
export -f getimagepath

getfilepath()
{
	filepath=$(echo $@ | sed -e "s/'$//")
	echo $filepath
}
export -f getfilepath

writeid3tag(){
	id3tag --artist="$1" --song="$2" "$3"
}
export -f writeid3tag

writeimage(){
	eyeD3 --add-image "$1:FRONT_COVER" "$2"
}
export -f writeimage

## File organization function 
organizefile()
{
	dirs=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

	for directory in "${dirs[@]}"
	    do
    	
    	if [ ! -d $directory ]; then 
			mkdir -p $directory 
		fi 

	    if [[ "$1" =~ ^[$directory] ]]; 
	 	then
	       mv "$1" "$directory"
   	       echo "----> $1 moved into -> $directory "
	       break
	    fi
	done
}
export -f organizefile

updatemetadata()
{
	artist=$(getartist "$1")
	echo "Artist: $artist"

	title=$(gettitle "$1")
	echo "Title: $title"

	imagepath=$(getimagepath "$1")
	echo "ImagePath: $imagepath"

	filepath=$(getfilepath "$1")
	echo "Filepath: $filepath"

	writeid3tag "$artist" "$title" "$filepath"
	writeimage "$imagepath" "$filepath"

	rm "$imagepath"

	if [[ $ORGANIZE == "true" ]]; then
		organizefile "$1"
	fi 
}
export -f updatemetadata


youtube-dl -i --download-archive "downloaded.txt" --no-post-overwrites -ciwx --write-thumbnail --no-call-home \
	--audio-format mp3 -o "%(title)s.%(ext)s" $PLAYLISTURL \
	--exec 'updatemetadata {}'



PERR=$(find . -name '*.jpg' -o -name '*.webm' -print)
if [[ ! -z $PERR ]]; then 
	echo "These files may not have downloaded correctly: "
	echo $PERR 
fi 

echo "Archival Complete"
