#!/bin/bash

echo "Script per l'organizzazzione di file flac"
echo
echo "La configurazione attuale è la seguente"
cat config.txt | sed 1d
echo
echo
echo "Modificarla?"
read YN
if [ "$YN" == "y" ]; then
    YN=''
    ./config.sh
fi

#Load config file
CONFIG_FILE=$(cat config.txt | tr -d [:blank:])
FFMPEG=$(echo "$CONFIG_FILE"| grep FFMPEG | sed "s/FFMPEG=//")
DIR_OUTPUT=$(echo "$CONFIG_FILE"| grep OUTPUT | sed "s/OUTPUT=//")
ENCODER=$(echo "$CONFIG_FILE"| grep ENCODER | sed "s/ENCODER=//")
EXTENSION=$(echo "$CONFIG_FILE"| grep EXTENSION | sed "s/EXTENSION=//")
BITRATE=$(echo "$CONFIG_FILE"| grep BITRATE | sed "s/BITRATE=//")

#Input files
while [ "$YN" != "y" ]; do
    echo "Inserire la directory in cui sono locati i file musicali"
    read -e DIR_INPUT
    echo "Hai scelto la cartella: $DIR_INPUT"
    ls "$DIR_INPUT"
    DIR_INPUT="$DIR_INPUT""/"
    echo "Va bene? (y = si, * = no)"
    read YN
done

#Splitting CUE
CUE=0
if [ -e "$DIR_INPUT"*.cue ]; then
    echo "E' stato rilevato un file .cue"
    echo "E' necessario lo split del file .flac?"
    read YN
    if [ "$YN" == "y" ]; then
	YN=''
       	./splitter_cue.sh "$DIR_INPUT"
	CUE=1
	DIR_INPUT_ORIGINAL="$DIR_INPUT"
	DIR_INPUT="$DIR_INPUT"/split/
    fi
fi

#Load Metadata
rm metadata.txt
exiftool "$DIR_INPUT"*.flac >> metadata.txt
ARTISTA=$(grep -m 1 Artist metadata.txt)
PREFISSO="Artist                          : "
ARTISTA=$(echo "$ARTISTA" | sed "s/^$PREFISSO//")
ALBUM=$(grep -m 1 Album metadata.txt)
PREFISSO="Album                           : "
ALBUM=$(echo "$ALBUM" | sed "s/^$PREFISSO//")
echo "L'Artista e'" $ARTISTA
echo "L'Album e'" $ALBUM
echo "Corretto? (* = si, n = no)"
read YN
if [ $YN == "n" ]; then #Da creare script apposta
    echo "Qual'e' l'Artista?"
    read ARTISTA
    echo "Qual'e' l'album?"
    read ALBUM
fi

id3 -a "$ARTISTA" -l "$ALBUM" "$DIR_INPUT"*.flac #Id3 Tagging
id3 -2 -a "$ARTISTA" -l "$ALBUM" "$DIR_INPUT"*.flac #Id3v2 Tagging

#Folder Creation
DIR_OUTPUT=$(echo "$DIR_OUTPUT""/""$ARTISTA""/""$ALBUM")
if [ $CUE == 1 ]; then
    mkdir -p "$DIR_OUTPUT"/FLAC\ -\ CUE
    cp "$DIR_INPUT_ORIGINAL"/*.flac "$DIR_OUTPUT"/FLAC\ -\ CUE
    cp "$DIR_INPUT_ORIGINAL"/*.cue "$DIR_OUTPUT"/FLAC\ -\ CUE
fi
DIR_OUTPUT_FLAC=$(echo "$DIR_OUTPUT"/FLAC)
EXTENSION=$(echo $EXTENSION | tr '[:lower:]' '[:upper:]')
DIR_OUTPUT=$(echo "$DIR_OUTPUT""/""$EXTENSION"" - ""$BITRATE"" KBs") #Da utilizzare sed per sostituire le minuscole con le maiuscole
EXTENSION=$(echo $EXTENSION | tr '[:upper:]' '[:lower:]')
echo "$DIR_OUTPUT"

mkdir -p "$DIR_OUTPUT"/ #crea, nel caso la cartella non sia gia' esistente, la directory di destinazione
mkdir -p "$DIR_OUTPUT_FLAC"
echo "DIR_OUTPUT" $DIR_OUTPUT >> log_ffpmeg-script.txt #crea un log della cartella appena creata, in caso bisogni eliminarla
n

#Converter
for i in "$DIR_INPUT"*.flac; do
    if [ -e "$i" ]; then
	file=$(basename -s .flac "$i")
  	"$DIR_FFMPEG"ffmpeg -i  "$i" -c:a "$ENCODER" -b:a "$BITRATE"k  "$DIR_OUTPUT"/"$file"."$EXTENSION"
	cp "$i" "$DIR_OUTPUT_FLAC"
    fi
done

#Cover Copier
echo "La copia della immagine di copertina andrà eseguita manualmente"
