#!/bin/bash

TYPES=(             'accommodation' 'amenity' 'education' 'food'    'health'  'landuse' 'money'   'place_of' 'poi'     'shopping' 'sport'   'tourist' 'transport' )
FORGROUND_COLOURS=( '#0092DA'       '#734A08' '#ffffff'   '#0092DA' '#ffffff' '#999999' '#ffffff' '#000000' '#000000'  '#ffffff'  '#39AC39' '#ffffff' '#ffffff' )
BACKGROUND_COLOURS=('none'          'none'    '#39AC39'   'none'    '#DA0092' 'none'    '#000000' 'none'     'none'    '#AC39AC'  'none'    '#734A08' '#0092DA')
SIZES=(32 24 20)
SIZES=(32)

for (( i = 0 ; i < ${#TYPES[@]} ; i++ )) do

  FOLDERNAME=${TYPES[i]}

  FOLDERNAME='recoloured'
  mkdir ${FOLDERNAME}

  for FILE in ${TYPES[i]}_*.svg; do
    for (( j = 0 ; j < ${#SIZES[@]} ; j++ )) do
      ./recolourtopng.sh ${FILE} ${BACKGROUND_COLOURS[i]} ${BACKGROUND_COLOURS[i]} ${FORGROUND_COLOURS[i]} ${SIZES[j]} ${FOLDERNAME}/${FILE%.*}.${SIZES[j]}
    done
#    ./recolour.sh ${FILE} ${BACKGROUND_COLOURS[i]} ${BACKGROUND_COLOURS[i]} ${FORGROUND_COLOURS[i]} > ${FOLDERNAME}/${FILE%.*}.svg
  done

done
