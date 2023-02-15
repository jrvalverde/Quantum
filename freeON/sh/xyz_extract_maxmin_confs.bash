#!/bin/bash

#
function xyz_extract_maxmin_confs() 
{
    local file=$1
    local nconfs=${2:-0}
    local -a minima=( )
    local -a maxima=( )
    local d f nam ext size prevE nextE currE n lastxyz left right i s e
    local minE maxE

    d=`dirname $file`
    f="${file##*/}"	# filename without path
    nam="${f%.*}"	# name without extension (nor path)
    ext="${f##*.}"	# extension
    
    if [ ! -s "$file" ] ; then
        echo "xyz_stract_min_conf: $f does not exist"
        return
    fi
    if [ "$ext" != "xyz" ] ; then
        echo "xyz_extract_min_conf: $f is not an XYZ file"
        return
    fi
    # get molecule size
    size=`head -n 1 "$file"`
    if [[ ! "$size" =~ ^\ *[0-9]+$ ]] ; then
        echo "xyz_extract_min_conf: invalid molecule size. Is this an XYZ file?"
        return
    fi
    
    n=0
    currE="0E00" 	
    prevE="0E00"	
    lastxyz=""
    minE="01.0E1000"
    maxE="-1.0E1000"
    nmin=0
    while read s ; do
        n=$(($n+1)) # count lines
        #echo "Size: $s"
	# if it is a molecule size line
        if [[ ! "$s" =~ ^\ *[0-9]+$ ]] ; then
	    continue
            echo "xyz_extract_min_conf: lost synchrony at line $n!"
            echo "                  Check that $file is in XYZ format."
        fi
        read e	# get line containing Energy info"
        x=$((x+1)) # count XYZ molecules/configurations
        #echo Energy: $e
        if [[ ! "$e" =~ ^Clone.* ]] ; then
            echo "xyz_extract_min_conf: lost synchrony at line $n!"
            echo "                  Check that $file is in XYZ format."
            continue
        fi
        # find out potential energy
        # if it is an optimization run we look for 
        #      <SCF> = xxxDxx Hartree, yyyDyyy eV
        # if it is an MD run we might look for 
        #      Epot = xxxDxxx eV
        # but the value is repeated at then of the line in an <SCF> entry
        #echo $e
        if [[ "$e" =~ .*\<SCF\>.* ]] ; then
            # extract the last energy in the line (in eV)
            nextE=`echo $e | sed -e 's/.*, //g' -e 's/ eV$//g' -e 's/D+/E/g'`
            #echo "Lowest: $loenergy Highest: $hienergy Curr: $energy"
        else
            echo "xyz_extract_hilo: Unknown energy in line"
            echo "    $e"
            return
        fi
        #echo "E-2=$prevE E-1=$currE E=$nextE"
        ###JR###
        # this will fail on a plateau (we should keep track of whether
        #	we are downhill or upfill) we rely on precision to not
        #	obtain exactly equal energies in consecutive points, or
        #	we could test for <= but then we would save all points
        #	in the plateau and should keep only one with "uniq" on column1
        left=`bc -l <<< "$currE < $prevE"`
        right=`bc -l <<< "$currE < $nextE"`
	#echo $left $right
        if [ "$left" == "1" -a "$right" == "1" ] ; then
            #echo "m $x: $prevE $currE $nextE" 
            #echo -n `bc -l <<< "    $prevE - $currE"`
            #echo `bc -l <<< "     $currE - $nextE"`
            #echo "local minimum found"
            # save its energy and XYZ in minima array
            #	they are those of the last read molecule
            minima=( "${minima[@]}" "$currE	$lastxyz" )
            # we could save memory if needed by doing the sort/tail here

            #echo "mv lastsaved to minimum"
            #for i in $(seq 1 $size) ; do
            #    echo "${lastconf[i]}"
            #done
        fi
        if [ "$left" == "0" -a "$right" == "0" ] ; then
            #echo "M $x: $prevE $currE $nextE" 
            #echo -n `bc -l <<< "    $prevE - $currE"`
            #echo `bc -l <<< "     $currE - $nextE"`
            maxima=( "${maxima[@]}" "$currE	$lastxyz" )
        fi
        #echo "save current as lastconf"
        #lastconf=( "$s" "$e" )
        #for i in $(seq 1 $size) ; do
        #    read l
        #    n=$(($n+1))
        #    lastconf=( "${lastconf[@]}" "$l" )
        #done 
        #lastxyz=`for i in $(seq 1 $size) ; do echo "${lastconf[i]}" ; done | tr '\n' '@'`
        lastxyz=`(echo "$s"; echo "$e"; \
        	  for i in $(seq 1 $size) ; do \
                      read l ; \
                      n=$(($n+1)) ; \
                      echo "$l" ; \
                  done) | tr '\n' '@'`

        prevE=$currE
        currE=$nextE
        
        if (( $(bc -l <<< "$currE <= $minE") )) ; then
            #echo "New minimum: $x $minE $currE"
            minxyz="$lastxyz"
            minE=$currE
        fi
        if (( $(bc -l <<< "$currE >= $maxE") )) ; then
            #echo "New maximum: $x $minE $currE"
            maxxyz="$lastxyz"
            maxE=$currE
        fi
    done < $file
    
    # last config is special: there is no next conf but it might also 
    # be a minimum
    if [ "$left" == "1" ] ; then
        minima=( "${minima[@]}" "$currE	$lastxyz" )
    fi
    # and by the way, we may as well save last, min and max
    echo "$lastxyz" | tr -d '\n' | tr '@' '\n' > $nam.lst.xyz
    echo "$minxyz"  | tr -d '\n' | tr '@' '\n' > $nam.min.xyz
    echo "$maxxyz"  | tr -d '\n' | tr '@' '\n' > $nam.max.xyz

    #for i in $(seq 0 ${#minima[@]}) ; do
    #    echo "$i: ${minima[$i]}"
    #done
    #echo ""
    #echo ""
    # sort minima array (which has the form E xyz@lined) and output lowest values
    if [ "$nconfs" -gt 0 ] ; then n=$nconfs ; else n=${#minima[@]} ; fi
    if [ ${#minima[@]} -lt $n ] ; then 
        echo "$n minima requested, but only ${#minima[@]} found"
        n=${#minima[@]} 
    fi
    for i in $(seq 0 ${#minima[@]}) ; do
        echo "${minima[$i]}"
    done |\
         grep -v '^$' | sort -g | head -n $n | \
         cut -f2 | tr -d '\n' | tr '@' '\n' \
         > $nam.min-$n.xyz
    # remove empty lines, sort numerically, select first $n, extract
    # the coordinates and revert back '@' to newlines

    # same for maxima
    if [ "$nconfs" -gt 0 ] ; then n=$nconfs ; else n=${#maxima[@]} ; fi
    if [ ${#maxima[@]} -lt $n ] ; then 
        echo "$n maxima requested, but only ${#maxima[@]} found"
        n=${#maxima[@]} 
    fi
    for i in $(seq 0 ${#maxima[@]}) ; do
        echo "${maxima[$i]}"
    done |\
         grep -v '^$' | sort -g | head -n $n | \
         cut -f2 | tr -d '\n' | tr '@' '\n' \
         > $nam.max-$n.xyz
}

xyz_extract_maxmin_confs $*
