#!/bin/bash
#
#   dGbind = -33.614 - 0.014HB - 0.076LIPO + 0.017ROT + 0.021BP + 0.026DESOLV
#

echo -n "`fresno -t`" 
echo "dG"
scores=( `fresno -x < $1` )
echo -n "${scores[*]}	" | tr ' ' '\t'
echo  "-33.614 - (0.014*${scores[1]}) - (0.076*${scores[2]}) + (0.017*${scores[3]}) + (0.021*${scores[7]}) + (0.026*${scores[6]})" | bc -l
