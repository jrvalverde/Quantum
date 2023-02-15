#!/bin/bash

mkdir files
cd files
ln -s ../trajectory geometries.xyz
csplit -n 4 -f traj- -b '%04d.xyz'  geometries.xyz /^ 49/ {*}
rm geometries.xyz
mkdir ../samples
for i in *00.xyz *25.xyz *50.xyz *75.xyz ; do 
	# format is
	#	^ atom-count$	(blank line)
	#	^Clone #n / t = .... fs, Ekin = .... eV, etc... $
	#	^ATOM    x    y    z    vx    vy    vz $
	#	...
	#
	# an XYZ file has
	#	atom-count
	#	comment-line
	#	ATOM x y z
	#	...
	#
	# we need to remove from the coordinate lines the last three series of 
	#		0 or more spaces
	#		0 or more -
	#		0 or more numbers
	#		a dot (required to avoid removing the atom count)
	#		0 or more numbers
	#		0 or more spaces
	#
	cat $i | sed -e \
	's/ *-*[0-9]*\.[0-9]* *-*[0-9]*\.[0-9]* *-*[0-9]*\.[0-9]* *$//g' \
	> ../samples/$i
	
#
#	# an alternative way	
#	echo " 49" > ../samples/$i 
#	cat $i | sed -e 's/[-\.0-9]* *[-\.0-9]* *[-\.0-9]* *$//g' | \
#		tail -n +2 >> ../samples/$i 
#	echo $i
#
done
cd ../samples
# carry out single-point calculation using ergoSCF
for i in *.xyz ; do
	~/contrib/ergoSCF/ergoHF.sh $i
done
