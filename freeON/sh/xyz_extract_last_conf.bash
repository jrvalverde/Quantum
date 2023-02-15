#!/bin/bash

# This is highly inefficient, we should use an array to hold
# intermediate configurations instead
# However, if we are lucky, buffered I/O will save us the day
#
function xyz_extract_last_conf() 
{
    local file=$1
    local d f nam ext molsiz l i n

    d=`dirname $file`
    f="${file##*/}"	# filename without path
    nam="${f%.*}"	# name without extension (nor path)
    ext="${f##*.}"	# extension
    
    if [ ! -s "$file" ] ; then
        echo "xyz_stract_last: $f does not exist"
        return
    fi
    if [ "$ext" != "xyz" ] ; then
        echo "xyz_extract_last: $f is not an XYZ file"
        return
    fi
    # get molecule size
    molsiz=`head -n 1 "$file"`
    if [[ ! "$molsiz" =~ ^\ *[0-9]+$ ]] ; then
        echo "xyz_extract_last: invalid molecule size. Is this an XYZ file?"
        return
    fi
    n=0    # line count used for error reporting
    cat $file | \
        while read l ; do
            n=$(($n+1))
	    # if it is a molecule size line
            #echo "<$l>" $molsiz
            if [[ "$l" =~ ^\ *[0-9]+$ ]] ; then
                # reset last-coordinates file
                echo "$l" > $d/$nam.last.xyz
                for i in $(seq 0 $molsiz) ; do
                    read l ; echo "$l" >> $d/$nam.last.xyz
                    n=$(($n+1))
                done
	    else
                echo "xyz_extract_last: lost synchrony at line $n!"
                echo "                  Check that $file is in XYZ format."
                rm $nam.last.xyz
            fi
        done
}

xyz_extract_last_conf $1
