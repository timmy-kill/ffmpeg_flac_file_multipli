#!/bin/bash


echo Experimental script to converto on the fly all your FLAC files from your output dir to another format

#Load Config file
CONFIG_FILE=$(cat config.txt | tr -d [:blank:])
DIR_FFMPEG=$(echo "$CONFIG_FILE"| grep FFMPEG | cut -d= -f2-)
MUSIC_DIR=$(echo "$CONFIG_FILE"| grep OUTPUT | cut -d= -f2-)
cd "$MUSIC_DIR"/"FLAC"

echo New format?
read FORMAT
FORMAT=$(echo "$FORMAT" | tr [:lower:] [:upper:])

mkdir "$MUSIC_DIR"/"$FORMAT"

for ARTISTA in *; do					#1 livello
	mkdir "$MUSIC_DIR"/"$FORMAT"/"$ARTISTA"
	cd "$ARTISTA"
	pwd
	for ALBUM in *; do				#2 livelli
		mkdir "$MUSIC_DIR"/"$FORMAT"/"$ARTISTA"/"$ALBUM"
		cd "$ALBUM"
		pwd
		for SONG in *.flac; do
			SONG=$( basename -s .flac "$SONG" )
			"$DIR_FFMPEG"ffmpeg -n -i "$SONG".flac "$MUSIC_DIR"/"$FORMAT"/"$ARTISTA"/"$ALBUM"/"$SONG".$(echo "$FORMAT" | tr [:upper:] [:lower:])
		done
	cd ..
	done
cd ..

done
