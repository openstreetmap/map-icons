
#!/bin/bash

TYPES=(             'accommodation' 'amenity' 'education' 'food'    'health'  'landuse' 'money'   'place_of' 'poi'     'shopping' 'sport'   'tourist' 'transport' )
FORGROUND_COLOURS=( '#0092DA'       '#734A08' '#39AC39'   '#734A08' '#DA0092' '#999999' '#000000' '#000000' '#000000'  '#AC39AC'  '#39AC39' '#734A08' '#0092DA' )
SIZES=(32 24 20 16 12 8)

for (( i = 0 ; i < ${#TYPES[@]} ; i++ )) do

  FOLDERNAME='../../../rendering/mapnik/symbols'

  for FILE in ${TYPES[i]}_*.svg; do
    for (( j = 0 ; j < ${#SIZES[@]} ; j++ )) do
      ./recolourtopng.sh ${FILE} 'none' 'none' ${FORGROUND_COLOURS[i]} ${SIZES[j]} ${FOLDERNAME}/${FILE%.*}.p.${SIZES[j]}
      ./recolourtopng.sh ${FILE} ${FORGROUND_COLOURS[i]} ${FORGROUND_COLOURS[i]} '#ffffff' ${SIZES[j]} ${FOLDERNAME}/${FILE%.*}.n.${SIZES[j]}
    done
  done

done
