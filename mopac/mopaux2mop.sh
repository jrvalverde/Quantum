mkdir steps
csplit -b '%04d' -f steps/step NoName.aux '/^ ATOM_X/' '{*}'

cd steps

export LD_LIBRARY_PATH=/home/scientific/contrib/mopac
mopac=~/contrib/mopac/MOPAC2012.exe

for i in step* ; do
    echo $i
    head -n 50 $i | \
    sed -e 's/  / /g' -e 's/  / /g' -e 's/^ //g' -e 's/ / 1 /g' -e 's/$/ 1/g' \
    > tmp
    cat head > $i.mop
    paste atoms tmp >> $i.mop
    $mopac $i.mop
done
rm tmp
bash jmol.sh 
