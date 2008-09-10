#!/bin/bash

TYPES=('none' 'whiteonorange' 'whiteonblue' 'black' 'whiteonbrown' 'blue' 'whiteonbluesmall')
SIZES=(100 16 32 32 32 32 24)
BACKGROUND_FILL=('none' 'none' '#0092DA' 'none' '#AC3939' 'none' '#0092DA')
BACKGROUND_STROKE=('none' 'none' '#0092DA' 'none' '#AC3939' 'none' '#0092DA')
FORGROUND_FILL=('none' '#E88814' '#fff' '#000' '#fff' '#0092DA' '#fff')
FORGROUND_STROKE=('none' '#E88814' '#fff' '#000' '#fff' '#0092DA' '#fff')

for (( i = 0 ; i < ${#SIZES[@]} ; i++ )) do

  FOLDERNAME=${TYPES[i]}
  mkdir ${FOLDERNAME}

  for FILE in *.svg; do
    ./recolourtopng.sh ${FILE} ${BACKGROUND_FILL[i]} ${BACKGROUND_STROKE[i]} ${FORGROUND_FILL[i]} ${SIZES[i]} ${FOLDERNAME}/${FILE%.*}.png
  done

done
