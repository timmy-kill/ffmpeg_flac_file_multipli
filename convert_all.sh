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
FORMAT=$(echo "$FORMAT" | tr [:lower:] [:upper:])

mkdir "$MUSIC_DIR"/"$FORMAT"






for ARTISTA in *; do					#1 livello
	mkdir "$MUSIC_DIR"/"$FORMAT"/"$ARTISTA"
	cd "$ARTISTA"
	pwd
	for ALBUM in *; do				#2 livelli
	    mkdir "$MUSIC_DIR"/"$FORMAT"/"$ARTISTA"/"$ALBUM"
	    cd "$ALBUM"	    
	    
	    for SONG in *.flac; do
		
		#Metadata
		FFPROBE=$(ffprobe "$SONG" 2>&1)
		ARTISTA_META=$(echo "$FFPROBE" | grep -m 1  ARTIST | cut -d: -f 2 | cut -c 2-)
		ALBUM_META=$(echo "$FFPROBE" | grep -m 1  ALBUM  | cut -d: -f 2 | cut -c 2-)
		ANNO_META=$(echo "$FFPROBE" | grep -m 1  DATE | cut -d: -f 2 | cut -c 2-)
		TRACK_META=$(echo "$FFPROBE" | grep -m 1  track | cut -d: -f 2 | cut -c 2-)		  

		    SONG=$( basename -s .flac "$SONG" )
			ffmpeg -n -i "$SONG".flac \
				     -write_id3v2 1 -metadata author="$ARTISTA_META" -metadata album="$ALBUM_META" -metadata year="$ANNO_META" -metadata track="$TRACK_META" \
				     "$MUSIC_DIR"/"$FORMAT"/"$ARTISTA"/"$ALBUM"/"$SONG".$(echo "$FORMAT" | tr [:upper:] [:lower:])

		done
	cd ..
	done
cd ..

done
