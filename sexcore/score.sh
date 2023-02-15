#!/bin/bash

export PATH=/u/jr/contrib/score/bin:$PATH

if [ ! -d score ] ; then mkdir score ; fi

cd score

if [ ! -e RESIDUE ] ; then ln -s /u/jr/contrib/score/RESIDUE . ; fi
if [ ! -e ATOMTYPE ] ; then ln -s /u/jr/contrib/score/score/ATOMTYPE . ; fi


if [ ! -e receptor.mol2 ] ; then ln -s ../receptor.mol2 . ; fi

if [ ! -e receptor.pdb ] ; then ln -s ../receptor.pdb . ; fi

if [ ! -e docked.mol2 ] ; then 
    if [ -s ../flex-grid-gbsa-0_secondary_conformers.mol2 ] ; then
	ln -s ../flex-grid-gbsa-0_secondary_conformers.mol2 docked.mol2
    else
	if [ -s ../flex-grid-gbsa-0_primary_conformers.mol2 ] ; then
            ln -s ../flex-grid-gbsa-0_primary_conformers.mol2 docked.mol2
	else
	  if [ -s ../docked.mol2 ] ; then
	    ln -s ../docked.mol2 .
	  else
            echo "ERROR: NOTHING TO SCORE"
	    exit
	  fi
	fi
    fi
fi

#
# split file at lines containing ###-- Name as many times as it appears
#
csplit -f lig -n 3 -z docked.mol2 '/^########## Name*/' '{*}' &> csplit.log

# we should verify that lig000 is empty
rm lig000

#
# score each individual ligand pose
#
if [  -e score_PK.txt ] ; then exit ; fi

touch score_PK.txt

for i in lig* ; do 
	echo -n "$i:" >> score_PK.txt
	score receptor.pdb $i >> score_PK.txt
	mv score.log $i.log 
	mv score.mol2 $i.mol2
done

cd ..
