#!/bin/bash

# This is highly inefficient, we should use an array to hold
# intermediate configurations instead
# However, if we are lucky, buffered I/O will save us the day
#
function xyz_extract_hilo_conf() 
{
    local file=$1
    local d f nam ext molsiz s e l i n energy loenergy hienergy

    d=`dirname $file`
    f="${file##*/}"	# filename without path
    nam="${f%.*}"	# name without extension (nor path)
    ext="${f##*.}"	# extension
    
    if [ ! -s "$file" ] ; then
        echo "xyz_stract_hilo: $f does not exist"
        return
    fi
    if [ "$ext" != "xyz" ] ; then
        echo "xyz_extract_hilo: $f is not an XYZ file"
        return
    fi
    # get molecule size
    molsiz=`head -n 1 "$file"`
    if [[ ! "$molsiz" =~ ^\ *[0-9]+$ ]] ; then
        echo "xyz_extract_hilo: invalid molecule size. Is this an XYZ file?"
        return
    fi
    n=0    # line count used for error reporting
    loenergy="01.0E1000" 	# ensure the first has a lower energy
    hienergy="-1.0E1000"	# ensure the first has a higher energy
    cat $file | \
        while read s ; do
            n=$(($n+1))
            #echo "Size: $s"
	    # if it is a molecule size line
            if [[ ! "$s" =~ ^\ *[0-9]+$ ]] ; then
                echo "xyz_extract_hilo: lost synchrony at line $n!"
                echo "                  Check that $file is in XYZ format."
                rm $nam.last.xyz
	    fi
            read e	# get line containing Energy info"
            n=$(($n+1))
            #echo Energy: $e
            if [[ ! "$e" =~ ^Clone.* ]] ; then
                echo "xyz_extract_hilo: lost synchrony at line $n!"
                echo "                  Check that $file is in XYZ format."
                rm $nam.last.xyz
                continue
            fi
            #echo "Updating last"
	    # update last configuration
            echo "$s" > $d/$nam.last.xyz
            echo "$e" >> $d/$nam.last.xyz                
            for i in $(seq 1 $molsiz) ; do
                read l ; echo "$l" >> $d/$nam.last.xyz
                n=$(($n+1))
            done
            # find out potential energy
            # if it is an optimization run we look for 
            #      <SCF> = xxxDxx Hartree, yyyDyyy eV
            # if it is an MD run we might look for 
            #      Epot = xxxDxxx eV
            # but the value is repeated at then of the line in an <SCF> entry
            #echo $e
            if [[ "$e" =~ .*\<SCF\>.* ]] ; then
                # it is an optimization run, extract the last eV energy
                energy=`echo $e | sed -e 's/.*, //g' -e 's/ eV$//g' -e 's/D+/E/g'`
                #echo "Lowest: $loenergy Highest: $hienergy Curr: $energy"
            elif [[ "$e" =~ .*Epot.* ]] ; then
                # Just in case (but it should not be needed)
                energy=`echo $e | sed -e 's/.*Epot = /g' -e ' eV.*//g' -e 's/D+/E/g'`
                #echo "LowestMD: $loenergy HighestMD: $hienergy Curr: $energy"
            else
                echo "xyz_extract_hilo: Unknown energy in line"
                echo "    $e"
                return
            fi
            if (( $(bc -l <<< "$energy <= $loenergy") )) ; then
                #echo "lower"
                loenergy=$energy
                # update lowest energy configuration on <=
                cp $d/$nam.last.xyz $d/$nam.lo.xyz
            fi
            if (( $(bc -l <<< "$energy >= $hienergy") )) ; then
                #echo "HIGHER"
                #echo "$energy >= $hienergy"
                hienergy=$energy
                # update highest energy configuration on >=
                cp $d/$nam.last.xyz $d/$nam.hi.xyz
                #exit
            fi
        done
}

xyz_extract_hilo_conf $1
