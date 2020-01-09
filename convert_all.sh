#!/bin/bash


echo Experimental script to converto on the fly all your FLAC files from your output dir to another format

#Load Config file
CONFIG_FILE=$(cat config.txt | tr -d [:blank:])
DIR_FFMPEG=$(echo "$CONFIG_FILE"| grep FFMPEG | cut -d= -f2-)
MUSIC_DIR=$(echo "$CONFIG_FILE"| grep OUTPUT | cut -d= -f2-)
DIR_FFPROBE=$(echo "$CONFIG_FILE"| grep FFPROBE | cut -d= -f2-)


cd "$MUSIC_DIR"/"FLAC"

echo New format?
read FORMAT
echo Encoder?
read ENCODER
echo New bitrate?
read BITRATE
FORMAT=$(echo "$FORMAT" | tr [:lower:] [:upper:])



for ARTISTA in *; do					#1 livello
	cd "$ARTISTA"
	pwd
	for ALBUM in *; do				#2 livelli
		DIR_OUTPUT="$MUSIC_DIR"/"$FORMAT - $BITRATE KBs"/"$ARTISTA"/"$ALBUM"
	   	mkdir -p "$DIR_OUTPUT"
	   	cd "$ALBUM"	    
	    
	    for SONG in *.flac; do
		
		#Metadata
		#FFPROBE=$(ffprobe "$SONG" 2>&1)
		#ARTISTA_META=$(echo "$FFPROBE" | grep -m 1  ARTIST | cut -d: -f 2 | cut -c 2-)
		#ALBUM_META=$(echo "$FFPROBE" | grep -m 1  ALBUM  | cut -d: -f 2 | cut -c 2-)
		#ANNO_META=$(echo "$FFPROBE" | grep -m 1  DATE | cut -d: -f 2 | cut -c 2-)
		#TRACK_META=$(echo "$FFPROBE" | grep -m 1  track | cut -d: -f 2 | cut -c 2-)		  

			SONG=$( basename -s .flac "$SONG" )
			ffmpeg -n -i "$(pwd)"/"$SONG".flac \
				-c:a "$ENCODER" -b:a "$BITRATE"k \
				"$DIR_OUTPUT"/"$SONG".$(echo "$FORMAT" | tr [:upper:] [:lower:])

		done
	cd ..
	done
cd ..

done
