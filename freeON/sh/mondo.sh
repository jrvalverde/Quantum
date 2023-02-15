#!/bin/bash
# Process an input file in a subdirectory and save auxiliary
# files on it as well
#
# (C) José R. Valverde, 2011

export MONDO_SCRATCH="."
export FREEON_SCRATCH="."
export MONDO_HOME=~/contrib/FreeON/
export FREEON_HOME=~/contrib/freeON
export MONDO_EXEC=$MONDO_HOME/bin
export FREON_EXEC=$FREEON_HOME/bin
export BASIS_SETS=$FREEON_HOME/share/freeon/BasisSets
export FREEON_BASISSETS=$FREEON_HOME/share/freeon/BasisSets

export PATH=$FREEON_EXEC:$PATH

nam=`basename $1 .inp`

if [ -e $nam ] ; then exit ; fi
mkdir $nam
cd $nam
ln -s ../$nam.inp .

date -u > $nam.date

FreeON $1 $nam.out $nam.log $nam.geometries &> $nam.std

date -u >> $nam.date

cd ..
