#!/bin/bash

TYPES=(             'accommodation' 'amenity' 'education' 'food'    'health'  'money'   'place_of' 'poi'     'shopping' 'sport'   'tourist' 'transport' )
FORGROUND_COLOURS=( '#0092DA'       '#AC3939' '#ffffff'   '#0092DA' '#ffffff' '#ffffff' '#000000' '#000000'  '#AC39AC'  '#39AC39' '#ffffff' '#ffffff' )
BACKGROUND_COLOURS=('none'          'none'    '#39AC39'   'none'    '#DA0092' '#000000' 'none'     'none'    'none'     'none'    '#AC3939' '#0092DA')
SIZES=(32 24 20)

for (( i = 0 ; i < ${#TYPES[@]} ; i++ )) do

  FOLDERNAME=${TYPES[i]}

  FOLDERNAME='recoloured'
  mkdir ${FOLDERNAME}

  for FILE in ${TYPES[i]}_*.svg; do
    for (( j = 0 ; j < ${#SIZES[@]} ; j++ )) do
      ./recolourtopng.sh ${FILE} ${BACKGROUND_COLOURS[i]} ${BACKGROUND_COLOURS[i]} ${FORGROUND_COLOURS[i]} ${SIZES[j]} ${FOLDERNAME}/${FILE%.*}.${SIZES[j]}
    done
    #./recolour.sh ${FILE} ${BACKGROUND_COLOURS[i]} ${BACKGROUND_COLOURS[i]} ${FORGROUND_COLOURS[i]} > ${FOLDERNAME}/${FILE%.*}.svg
  done

done
