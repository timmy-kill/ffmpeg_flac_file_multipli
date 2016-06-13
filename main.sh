#!/bin/bash

echo "Script per l'organizzazzione di file flac"
echo
echo "La configurazione attuale è la seguente"
cat config.txt
echo
echo
echo "Modificarla?"
read YN
if [ "$YN" == "y" ]; then
    YN=''
    ./config.sh
fi

#Load config file
FFMPEG=$(cat config.txt| grep FFMPEG | sed "s/FFMPEG = //")
OUTPUT=$(cat config.txt| grep OUTPUT | sed "s/OUTPUT = //")
ENCODER=$(cat config.txt| grep ENCODER | sed "s/ENCODER = //")
EXTENSION=$(cat config.txt| grep EXTENSION | sed "s/EXTENSION = //")
BITRATE=$(cat config.txt| grep BITRATE | sed "s/BITRATE = //")

#Input files
while [ "$YN" != "y" ]; do
    echo "Inserire la directory in cui sono locati i file musicali"
    read -e DIR_INPUT
    echo "Hai scelto la cartella: $DIR_INPUT"
    ls "$DIR_INPUT"
    echo "Va bene? (y = si, * = no)"
    read YN
done

#Splitting CUE
echo "E' necessario lo split del file .flac?"
read YN
if [ "$YN" == "y" ]; then
    YN=''
    ./splitter_cue.sh $DIR_INPUT
fi

#Load Metadata
exiftool *.flac >> metadata.txt
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
    #Da aggiungere il tag dei files
fi

#Folder Creation
DIR_OUTPUT=$(echo "$DIR_OUTPUT""/""$ARTISTA""/""$ALBUM")
DIR_OUTPUT_FLAC=$(echo "$DIR_OUTPUT"/FLAC)
DIR_OUTPUT=$(echo "$DIR_OUTPUT""/""$EXTENSION""/""$BITRATE"" - KBs") #Da utilizzare sed per sostituire le minuscole con le maiuscole
echo "$DIR_OUTPUT"

mkdir -p "$DIR_OUTPUT"/ #crea, nel caso la cartella non sia gia' esistente, la directory di destinazione
mkdir -p "$DIR_OUTPUT_FLAC"
echo "DIR_OUTPUT" $DIR_OUTPUT >> log_ffpmeg-script.txt #crea un log della cartella appena creata, in caso bisogni eliminarla

#Converter
for i in "$DIR_INPUT"*.flac; do
    if [ -e "$i" ]; then
  	"$DIR_FFMPEG" -i  "$i" -c:a "$ENCODER" -b:a "$bitrate"k  "$DIR_OUTPUT"/"$file"."$EXTENSION"
	cp "$i" $DIR_OUTPUT_LOSSLESS
    fi
done

#Cover Copier
echo "La copia della immagine di copertina andrà eseguita manualmente"
