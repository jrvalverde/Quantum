#!/bin/bash
orb=$1

homo=15
lumo=16
if [ $orb == 'homo' ] ; then
    mo=$homo
else
  if [ $orb == 'lumo' ] ; then
    mo=$lumo
  else
    mo=$orb
  fi
fi
if [ ! -d $orb ] ; then mkdir $orb ; fi
for i in step*.mgf ; do
name=`basename $i .mgf`
if [ ! -e $orb/$name.png ] ; then
cat > jmol-$orb.cmd <<END
load "$name.mgf"
isoSurface mo $mo
write IMAGE 800 600 PNG 10 "$orb/$name.png"
END
jmol -s jmol-$orb.cmd -n -x
fi
done
convert $orb/*.png $orb.mpg
