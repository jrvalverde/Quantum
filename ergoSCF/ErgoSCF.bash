#!/bin/bash
#
#	ErgoSCF.bash
#
#	A driver program to run ergoSCF more easily. It tries to provide
#   some heuristics but -to my taste- it still requires a additional
#   intelligence to better exploit ergoSCF capabilities.
#
#	Note that it does not support yet some recent additions to ergoSCF
#   such as gradient calculation. They will be added in a near future. For
#   now, it supports the calculations I mostly need, if you have an interest
#   in any other, contact me and I'll do my best to add support for it.
#
#	COROLLARY: This is still a work in flux, undergoing continuous
#   development, currently driven by my own needs, but open to others'
#   requests and suggestions.
#
#	NOTE: this driver will check if there exist several versions of
#   ergoSCF using differing precisions (named ergo-single, ergo-double,
#   ergo-long, or just "ergo" for the default) and choose one using
#   its own heuristic (see code below).
#
#	(C) 2013-2015, Jose R Valverde. CNB/CSIC
#	jrvalverde@cnb.csic.es
#
#	Licensed under EU-GPL
#
#set -x

# Systems with more than this number of atoms are considered large
LARGE_SYSTEM_SIZE=500

# we need extended globs for testing for integers
shopt -s extglob

# No longer needed as we do it directly in bash now
#calc_elec="python $HOME/contrib/jr/calc_e-.py"

export ERGO_HOME=$HOME/contrib/ergoSCF
#export ERGO_HOME=/opt/quantum/ergoSCF
#export ERGO_HOME=/usr

export PATH=$ERGO_HOME/bin:$PATH

babel=`which babel`

# declare an array of element symbols
declare -a ELEMS=(\
"H"                                                                                                                                                           "HE" \
"LI" "BE"                                                                                                                         "B"   "C"  "N"   "O"  "F"   "NE" \
"NA" "MG"                                                                                                                         "AL"  "SI" "P"   "S"  "CL"  "AR" \
"K"  "CA" "SC"                                                                       "TI" "V"  "CR" "MN" "FE" "CO" "NI" "CU" "ZN" "GA"  "GE" "AS"  "SE" "BR"  "KR" \
"RB" "SR" "Y"                                                                        "ZR" "NB" "MO" "TC" "RU" "RH" "PD" "AG" "CD" "IN"  "SN" "SB"  "TE" "I"   "XE" \
"CS" "BA" "LA" "CE" "PR" "ND" "PM" "SM" "EU" "GD" "TB" "DY" "HO" "ER" "TM" "YB" "LU" "HF" "TA" "W"  "RE" "OS" "IR" "PT" "AU" "HG" "TL"  "PB" "BI"  "PO" "AT"  "RN" \
"FR" "RA" "AC" "TH" "PA" "U"  "NP" "PU" "AM" "CM" "BK" "CF" "ES" "FM" "MD" "NO" "LR" "RF" "DB" "SG" "BH" "HS" "MT" "DS" "RG" "CN" "UUT" "FL" "UUP" "LV" "UUS" "UUO" )

export ELEMS


# NAME
# 	banner - print large banner
#
# SYNOPSIS
#	banner text
#
# DESCRIPTION
#	banner prints out the first 10 characters of "text" in large letters
#
function banner {
    #
    # Taken from http://stackoverflow.com/questions/652517/whats-the-deal-with-the-banner-command
    #
    #	Msg by jlliagre
    #		Apr 15 '12 at 11:52
    #
    # ### JR ###
    #	Input:	A text up to 10 letter wide
    # This has been included because banner(1) is no longer a standard
    # tool in many Linux systems. This way we avoid having a dependency
    # that might not be met.
    # It is often installed through package 'sysvbanner'
    #	npm has an ascii-banner tool (npm -g install ascii-banner)
    # Other alternatives are toilet(1) and figlet(1)

    typeset A=$((1<<0))
    typeset B=$((1<<1))
    typeset C=$((1<<2))
    typeset D=$((1<<3))
    typeset E=$((1<<4))
    typeset F=$((1<<5))
    typeset G=$((1<<6))
    typeset H=$((1<<7))

    function outLine
    {
      typeset r=0 scan
      for scan
      do
        typeset l=${#scan}
        typeset line=0
        for ((p=0; p<l; p++))
        do
          line="$((line+${scan:$p:1}))"
        done
        for ((column=0; column<8; column++))
          do
            [[ $((line & (1<<column))) == 0 ]] && n=" " || n="#"
            raw[r]="${raw[r]}$n"
          done
          r=$((r+1))
        done
    }

    function outChar
    {
        case "$1" in
        (" ") outLine "" "" "" "" "" "" "" "" ;;
        ("0") outLine "BCDEF" "AFG" "AEG" "ADG" "ACG" "ABG" "BCDEF" "" ;;
        ("1") outLine "F" "EF" "F" "F" "F" "F" "F" "" ;;
        ("2") outLine "BCDEF" "AG" "G" "CDEF" "B" "A" "ABCDEFG" "" ;;
        ("3") outLine "BCDEF" "AG" "G" "CDEF" "G" "AG" "BCDEF" "" ;;
        ("4") outLine "AF" "AF" "AF" "BCDEFG" "F" "F" "F" "" ;;
        ("5") outLine "ABCDEFG" "A" "A" "ABCDEF" "G" "AG" "BCDEF" "" ;;
        ("6") outLine "BCDEF" "A" "A" "BCDEF" "AG" "AG" "BCDEF" "" ;;
        ("7") outLine "BCDEFG" "G" "F" "E" "D" "C" "B" "" ;;
        ("8") outLine "BCDEF" "AG" "AG" "BCDEF" "AG" "AG" "BCDEF" "" ;;
        ("9") outLine "BCDEF" "AG" "AG" "BCDEF" "G" "G" "BCDEF" "" ;;
        ("a") outLine "" "" "BCDE" "F" "BCDEF" "AF" "BCDEG" "" ;;
        ("b") outLine "B" "B" "BCDEF" "BG" "BG" "BG" "ACDEF" "" ;;
        ("c") outLine "" "" "CDE" "BF" "A" "BF" "CDE" "" ;;
        ("d") outLine "F" "F" "BCDEF" "AF" "AF" "AF" "BCDEG" "" ;;
        ("e") outLine "" "" "BCDE" "AF" "ABCDEF" "A" "BCDE" "" ;;
        ("f") outLine "CDE" "B" "B" "ABCD" "B" "B" "B" "" ;;
        ("g") outLine "" "" "BCDEG" "AF" "AF" "BCDE" "F" "BCDE" ;;
        ("h") outLine "B" "B" "BCDE" "BF" "BF" "BF" "ABF" "" ;;
        ("i") outLine "C" "" "BC" "C" "C" "C" "ABCDE" "" ;;
        ("j") outLine "D" "" "CD" "D" "D" "D" "AD" "BC" ;;
        ("k") outLine "B" "BE" "BD" "BC" "BD" "BE" "ABEF" "" ;;
        ("l") outLine "AB" "B" "B" "B" "B" "B" "ABC" "" ;;
        ("m") outLine "" "" "ACEF" "ABDG" "ADG" "ADG" "ADG" "" ;;
        ("n") outLine "" "" "BDE" "BCF" "BF" "BF" "BF" "" ;;
        ("o") outLine "" "" "BCDE" "AF" "AF" "AF" "BCDE" "" ;;
        ("p") outLine "" "" "ABCDE" "BF" "BF" "BCDE" "B" "AB" ;;
        ("q") outLine "" "" "BCDEG" "AF" "AF" "BCDE" "F" "FG" ;;
        ("r") outLine "" "" "ABDE" "BCF" "B" "B" "AB" "" ;;
        ("s") outLine "" "" "BCDE" "A" "BCDE" "F" "ABCDE" "" ;;
        ("t") outLine "C" "C" "ABCDE" "C" "C" "C" "DE" "" ;;
        ("u") outLine "" "" "AF" "AF" "AF" "AF" "BCDEG" "" ;;
        ("v") outLine "" "" "AG" "BF" "BF" "CE" "D" "" ;;
        ("w") outLine "" "" "AG" "AG" "ADG" "ADG" "BCEF" "" ;;
        ("x") outLine "" "" "AF" "BE" "CD" "BE" "AF" "" ;;
        ("y") outLine "" "" "BF" "BF" "BF" "CDE" "E" "BCD" ;;
        ("z") outLine "" "" "ABCDEF" "E" "D" "C" "BCDEFG" "" ;;
        ("A") outLine "D" "CE" "BF" "AG" "ABCDEFG" "AG" "AG" "" ;;
        ("B") outLine "ABCDE" "AF" "AF" "ABCDE" "AF" "AF" "ABCDE" "" ;;
        ("C") outLine "CDE" "BF" "A" "A" "A" "BF" "CDE" "" ;;
        ("D") outLine "ABCD" "AE" "AF" "AF" "AF" "AE" "ABCD" "" ;;
        ("E") outLine "ABCDEF" "A" "A" "ABCDE" "A" "A" "ABCDEF" "" ;;
        ("F") outLine "ABCDEF" "A" "A" "ABCDE" "A" "A" "A" "" ;;
        ("G") outLine "CDE" "BF" "A" "A" "AEFG" "BFG" "CDEG" "" ;;
        ("H") outLine "AG" "AG" "AG" "ABCDEFG" "AG" "AG" "AG" "" ;;
        ("I") outLine "ABCDE" "C" "C" "C" "C" "C" "ABCDE" "" ;;
        ("J") outLine "BCDEF" "D" "D" "D" "D" "BD" "C" "" ;;
        ("K") outLine "AF" "AE" "AD" "ABC" "AD" "AE" "AF" "" ;;
        ("L") outLine "A" "A" "A" "A" "A" "A" "ABCDEF" "" ;;
        ("M") outLine "ABFG" "ACEG" "ADG" "AG" "AG" "AG" "AG" "" ;;
        ("N") outLine "AG" "ABG" "ACG" "ADG" "AEG" "AFG" "AG" "" ;;
        ("O") outLine "CDE" "BF" "AG" "AG" "AG" "BF" "CDE" "" ;;
        ("P") outLine "ABCDE" "AF" "AF" "ABCDE" "A" "A" "A" "" ;;
        ("Q") outLine "CDE" "BF" "AG" "AG" "ACG" "BDF" "CDE" "FG" ;;
        ("R") outLine "ABCD" "AE" "AE" "ABCD" "AE" "AF" "AF" "" ;;
        ("S") outLine "CDE" "BF" "C" "D" "E" "BF" "CDE" "" ;;
        ("T") outLine "ABCDEFG" "D" "D" "D" "D" "D" "D" "" ;;
        ("U") outLine "AG" "AG" "AG" "AG" "AG" "BF" "CDE" "" ;;
        ("V") outLine "AG" "AG" "BF" "BF" "CE" "CE" "D" "" ;;
        ("W") outLine "AG" "AG" "AG" "AG" "ADG" "ACEG" "BF" "" ;;
        ("X") outLine "AG" "AG" "BF" "CDE" "BF" "AG" "AG" "" ;;
        ("Y") outLine "AG" "AG" "BF" "CE" "D" "D" "D" "" ;;
        ("Z") outLine "ABCDEFG" "F" "E" "D" "C" "B" "ABCDEFG" "" ;;
        (".") outLine "" "" "" "" "" "" "D" "" ;;
        (",") outLine "" "" "" "" "" "E" "E" "D" ;;
        (":") outLine "" "" "" "" "D" "" "D" "" ;;
        ("!") outLine "D" "D" "D" "D" "D" "" "D" "" ;;
        ("/") outLine "G" "F" "E" "D" "C" "B" "A" "" ;;
        ("\\") outLine "A" "B" "C" "D" "E" "F" "G" "" ;;
        ("|") outLine "D" "D" "D" "D" "D" "D" "D" "D" ;;
        ("+") outLine "" "D" "D" "BCDEF" "D" "D" "" "" ;;
        ("-") outLine "" "" "" "BCDEF" "" "" "" "" ;;
        ("*") outLine "" "BDF" "CDE" "D" "CDE" "BDF" "" "" ;;
        ("=") outLine "" "" "BCDEF" "" "BCDEF" "" "" "" ;;
        (*) outLine "ABCDEFGH" "AH" "AH" "AH" "AH" "AH" "AH" "ABCDEFGH" ;;
        esac
    }

    function outArg
    {
      typeset l=${#1} c r
      for ((c=0; c<l; c++))
      do
        outChar "${1:$c:1}"
      done
      echo
      for ((r=0; r<8; r++))
      do
        printf "%-*.*s\n" "${COLUMNS:-80}" "${COLUMNS:-80}" "${raw[r]}"
        raw[r]=""
      done
    }

    for i
    do
      outArg "$i"
      echo
    done
}


# NAME
#    usage
#
# SYNOPSIS
#    usage ; exit
#
# DESCRIPTION
#    Print an explanation on how to use the program
#
#    (c) José R. Valverde
#
function usage {
    echo ""
    echo "$0: Carry out a ground-state HF calculation using ergoSCF"
    echo ""
    echo "Usage:"
    echo "    $0 -i file -c charge -g basis -b basis -l -r -u -C -h -m method "
    echo "        -x XCtype -p precision -a accuracy"
    echo ""
    echo "    $0 --input file --charge charge --guess basis --basis basis "
    echo "       --large --rhf --uhf --CI --help --method method"
    echo "        --XC XC(r.q.g.)type --precision precision --accuracy accuracy"
    echo ""
    echo "    -i --input	an XYZ, MOL2 file name"
    echo "    -c --charge	charge of the molecule"
    echo "    -g --guess        basis set for initial guess"
    echo "    -b --basis        basis set to use for calculation"
    echo "                      (specify 'help' for a list of available basis sets)"
    echo "    -l --large        use parameters for large systems" 
    echo "    -r --rhf          force use of restricted Hertree-Fock" 
    echo "    -u --uhf          force use of unrestricted Hertree-Fock" 
    echo "    -C --CI           do CI after HF" 
    echo "    -h --help         print this help"
    echo "    -m --method       the method to use for the calculation:" 
    echo "                      (use 'help' for a list of options)"
    echo "    -x --XC           type of XC radial quadrature grid to use"
    echo "                      (use 'help' for a list of options)"
    echo "                      (only used is method is not HF)"
    echo "    -p --precision    precision to use in the calculation"
    echo "                      (default, single, double, long), use"
    echo "                      'help' for a list of options"
    echo "    -a --accuracy     accuracy to rach during the computation"
    echo "                      (used as SCF convergence threshold)"
    echo "                      expressed in scientific notation as"
    echo "                      #.##e±# (default is 1e-6). You may wish"
    echo "                      to reduce it if you have convergence problems"
    echo ""
    echo "In case of conflicting options the last one will be used"
    echo ""
    exit
}


# NAME
#    charge_help
#
# SYNOPSIS
#    charge_help ; exit
#
# DESCRIPTION
#    Explain how to use the -c --charge command line switch
#
#    (c) José R. Valverde
#
function charge_help() {
    echo "
    -c --charge charge
    
    Specify the charge of your system using a positive or negative
  natural number, for example
  
      $ME -c -2
    
    An ion is an atom or molecule in which the total number of e- does
  not equal the total number of protons in the nucleus, giving the 
  molecule a net positive or negative charge.
  
"
    return
}


# NAME
#    is_int()
#
# SYNOPSIS
#    usage: if is_int value ; then ... else .. fi
#
# DESCRIPTION
#    Test if value is an integer (positive, negative or zero)
#
#    (c) José R. Valverde
#
function is_int() {
#    return $(test "$@" -eq "$@" > /dev/null 2>&1)
#    if [[ $@ == [0-9]* ]] ; return 1 ; fi
    if [[ $@ =~ ^-?\+?[0-9]+$ ]] ; then return 1 ; fi
}

# NAME
#    calc_e()
#
# SYNOPSIS
#    usage: nelec=calc_e moleculefile charge
#
# DESCRIPTION
#    Calculate the total number of electrons in a molecule contained
# in an XYZ file, taking into account the specified charge of the molecule
#
#    (c) José R. Valverde
#
function calc_e() {
    # file must be an XYZ file
    local f=$1

    # list only basis sets valid with support for all atoms in
    # the molecule to analyze
    #
    # get list of atoms
    local nelec=0
    while read atom ; do
        # convert atom names to numbers
        for (( i = 0; i < ${#ELEMS[@]}; i++ )); do
           if [ "${ELEMS[$i]}" = "$atom" ]; then
               nelec=$(($nelec + $i + 1))
               #echo "$atom $(($i + 1)) $nelec"
               break
           fi
        done        
    done < <(tail -n +3 $f | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')
    echo $nelec
    return $nelec
}

function list_basis_sets() {
    # file must be an XYZ file
    local f=$1
    
    # list only basis sets valid with support for all atoms in
    # the molecule to analyze
    #
    
    if [ "$f" == "" ] ; then
        ls -C $ERGO_HOME/share/ergo/basis | grep -v Makefile | less
        exit
    fi
    
    echo "List of valid basis sets for your input molecule $f"
    echo ""

    # initially all basis sets are valid
    ls -1 $ERGO_HOME/share/ergo/basis/* > tmpVBS

    # get list of atoms
    tail -n +3 $f | cut -d' ' -f1 | sort | uniq | tr '[:lower:]' '[:upper:]' | \
    while read atom ; do
        # convert atom names to numbers
        for (( i = 0; i < ${#ELEMS[@]}; i++ )); do
           if [ "${ELEMS[$i]}" = "$atom" ]; then
               #lookup atom in list of valid basis sets
               # and make a new list 
               grep -l -E "^[Aa] +$((i+1))\b" `cat tmpVBS | tr '\n' ' '` > tmpVBS.new
               mv tmpVBS.new tmpVBS
               break
           fi
        done        
    done
    # print neatly
    sed 's%.*/%%g' tmpVBS | column #| less
    rm tmpVBS
    exit
}

function list_methods() {
    echo ""
    echo "Available computation methods"
    echo ""
    echo "    HF        Classical Hartree-Fock SCF"
    echo "    LDA       DFT using the Local Density Approximation"
    echo "    BLYP      DFT using Becke-Lee-Yang-Parr functional"
    echo "    B3LYP     Hybrid functional combining Becke's functional"
    echo "              with exact energy from Hartree-Fock theory"
    echo "    CAMB3LYP  Handy et al. B3LYP corrected for long-range"
    echo "    BHANDHLYP Half-and-half functional combining HF, LSDA, Becke88 and LYP"
    echo "    BPW91     Hybrid DFT functional of Becke88 and Perdew and Wangs's 91"
    echo ""
    exit
}

function list_xctype() {
    echo ""
    echo "Available calculation types for the XC functional"
    echo "    HiCu      Hybrid Cubature linear scaling grid"
    echo "    LMG       Lindh, Malmqvist and Gagliardi grid"
    echo "    Turbo     Treutler-Ahlrichs M4-T2 scheme"
    echo "    GC2	Gauss-Chevychev second order radial quadrature scheme"
    echo ""
    exit
}

function list_precisions() {
    echo ""
    echo "available precisions:"
    if [ -x $ERGO_HOME/bin/ergo ] ; then
	echo "default	- use system default: "`$ERGO_HOME/bin/ergo -e precision`
 	rm ergoscf.out
    fi
    if [ -x $ERGO_HOME/bin/ergo-single ] ; then
        echo "single	- use single precision"
    fi
    if [ -x $ERGO_HOME/bin/ergo-double ] ; then
        echo "double	- use double precision"
    fi
    if [ -x $ERGO_HOME/bin/ergo-long ] ; then
        echo "long	- use long double precision"
    fi
    echo ""
    exit
}

function mol2toxyz() {
    local file=$1
    
    if [ ! -s $file ] ; then echo "$ME.mol2toxyz ERROR: invalid input file" ; return ; fi
    # extract file extension
    local ext="${file##*.}"
    # remove file extension
    local base="${file%.*}"
    # $base contains the path name, hence everything
    # will happen at the destination path name

    #
    # generate an XYZ from a mol2 file
    #
    if [ "$ext" == "mol2" -a ! -s $base.xyz ] ; then
        local i=0
        while read no atom x y z typ n res charge ; do
            i=$((i + 1))
            echo "$atom    $x    $y    $z" >> $base.zyx
        done < <( sed -n '/ATOM/,/BOND/ {/ATOM/d;/BOND/d;p}' $file )
	#        ^select between ATOM and BOND and delete these
        #         two lines
        echo "$i" > $base.xyz
        echo "$base" >> $base.xyz
        cat $base.zyx >> $base.xyz
        rm $base.zyx
    fi
}


function dalton2xyz() {
    local file="$1"
    local OFS
    
    if [ ! -s $file ] ; then echo "$ME.dalton2toxyz ERROR: invalid input file" ; return ; fi
    # extract file extension
    local ext="${file##*.}"
    # remove file extension
    local base="${file%.*}"
    # $base contains the path name, hence everything
    # will happen at the destination path name

    #
    # generate an XYZ from a Dalton file
    # using lines starting with letters and containing three dots
    #    NOTE: we check if it starts with BASIS or other keywoord
    #    and jump the required number of lines (5 or 4) before the grep
    #    and also save the first comment line to output it to the 
    #    XYZ file.
    #
    l=`head -n 1 "$file"`
    if [[ "$l" = "^BASIS*" ]] ; then
        jump=5
        comment=`tail -n +3 "$file" | head -n 1`
    else
        jump=4
        comment=`tail -n +3 "$file" | head -n 1`
    fi
    OFS=$IFS ; IFS=$'\n' ; coords=( `tail -n +$jump $file | grep -e "[A-Za-z]*.*\..*\..*\..*"` ) ; IFS=$OFS
    echo "${#coords[@]}" > $base.xyz
    echo "$comment" >> $base.xyz
    for l in "${coords[@]}" ; do
        echo "$l" >> $base.xyz
    done
}


function xyz_dimensions() {
    # compute the dimensions of an XYZ file
    f=$1
    
    {
        read natoms
        read desc
        read atom maxx maxy maxz
        minx=$maxx ; miny=$maxy ; minz=$maxz   
        while read atom x y z ; do
            if [ "$atom" = "" -o "$x" = "" -o "$y" = "" -o "$z" = "" ] ; then
	        # this is not a valid coordinate line
                break  # for single-molecule files
                #continue # for multiple-coordinates files
            fi
            if (( $(bc -l <<< "$x <= $minx") )) ; then
                minx=$x
            else
                maxx=$x
            fi
            if (( $(bc -l <<< "$y <= $miny") )) ; then
                miny=$y
            else
                maxy=$y
            fi
            if (( $(bc -l <<< "$z <= $minz") )) ; then
                minz=$z
            else
                maxz=$z
            fi
        done
    } < "$f"
    x=`bc -l <<< "$maxx - $minx"`
    y=`bc -l <<< "$maxy - $miny"`
    z=`bc -l <<< "$maxz - $minz"`
    #echo "$maxx $maxy $maxz"
    #echo "$minx $miny $minz"
    echo "$x $y $z"
    return
}


# default values
ME=`basename $0`

MOL="input.xyz"
CHARGE=0
GUESS="NOGUESS"
BASIS="NOBASIS"
LARGE="no"
RHF=0
UHF=0
CI=0
SPIN=0
VERBOSE=0
METHOD="HF"
XC="HICU"
PRECISION="default"	# default or single or double or long
ACCURACY="1e-6"		# SCF convergence threshold

# Parse the command line
# ----------------------
# Note that we use `"$@"' to let each command-line parameter expand to a 
# separate word. The quotes around `$@' are essential!
# We need TEMP as the `eval set --' would nuke the return value of getopt.
TEMP=`getopt -o hi:c:b:g:m:x:p:a:n:lruCv \
     --long help,input:,charge:,basis:,guess:,method:,XC:,precision:,accuracy:,num-threads:,large,rhf,uhf,CI,verbose \
     -n "$0" -- "$@"`

# an invalid option was given
if [ $? != 0 ] ; then usage >&2 ; exit 1 ; fi
#
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
        case "$1" in
                -h|--help) 
                    usage ; shift ;;

                -i|--input) 
                    # NOTE: consider using -m --molecule instead for
                    #   coherece with ergoSCF command line
                    #echo "INPUT FILE \`$2'" 
                    FILE=$2 ; shift 2 ;;
                    
                -c|--charge)
                    # if $2 is an integer number, use it, ignore otherwise
                    # NOTE: we should check if it is a file and then use it
                    # as an extra-charges molecule file-name!
                    if [[ $2 =~ ^-?\+?[0-9]+$ ]] ; then 
                        CHARGE=$2 
                    else
                        charge_help ; exit
                    fi
                    shift 2 ;;

                -b|--basis) 
                    BASIS=$2 ; shift 2 ;;
                
                -g|--guess) 
                    GUESS=$2 ; shift 2 ;;
                
                -l|--large) 
                    LARGE="yes" ; shift ;;

                -r|--rhf) 
                    RHF=1 ; UHF=0 ; shift ;;

                -u|--uhf) 
                    RHF=0 ; UHF=1 ; shift ;;

                -C|--CI) 
                    CI=1 ; shift ;;

                -v|--verbose) 
                    VERBOSE=$(( $VERBOSE + 1 )) ; shift ;;
                    
                -m|--method) 
                    METHOD=$2 ; shift 2 ;;

                -x|--XC) 
                    XC=$2 ; shift 2 ;;

                -p|--precision) 
                    PRECISION=$2 ; shift 2 ;;

                -a|--accuracy) 
                    ACCURACY=$2 ; shift 2 ;;
                
                -n|--num-threads)
                    if [[ $2 =~ ^+?[0-9]+$ ]] ; then 
                        export OMP_NUM_THREADS=$2 
                    fi
                    shift 2 ;;

                --) shift ; break ;;
                *) echo "Internal error!" >&2 ; usage ; exit 1 ;;
        esac
done

if [ "$PRECISION" == "help" ] ; then
    list_precisions
fi

if [ "$METHOD" == "help" ] ; then
    list_methods
fi

if [ "$XC" == "help" ] ; then
    list_xctype
fi

if [ $VERBOSE -gt 0 ] ; then
    banner " ErgoSCF  "
fi

# check if the filename was specified as an unnamed argument
file=${1:-""} ; shift

# get file name from environment variable as a last resort
#       We allow the input file not to be specified in the
#       command line, so it may be taken from an environment
#       variable when run in batch mode.
#       This is OK as we only want this for batch submission
#       when we cannot give any command line arguments: if 
#       we got it from a command line arg. then we are not in batch
#       mode.
#       Provide a safe default.
if [ "$file" == "" ] ; then
    file=${FILE:-$MOL}
fi

# get file's directory and move to it
#
#       if $FILE undefined this will return "."
d=`dirname "$file"`
pushd `pwd` > /dev/null
cd $d


# remove directory path
f="${file##*/}"
# extract file extension
ext="${file##*.}"
# remove file extension
base="${f%.*}"

# allow molecule name to be specified without extension
if [ "$base" == "$f" ] ; then 
    # no extension specified
    if [ -s $f.mol2 ] ; then 
        ext="mol2" 
        f=$f.mol2 
    elif [ -s $f.mol ] ; then
        ext="mol" 
        f=$f.mol
    elif [ -s $f.inp ] ; then
        ext="inp" 
        f=$f.inp
    elif [ -s $f.xyz ] ; then
        ext="xyz" 
        f=$f.xyz
    fi
    # if no complete filename exists, then, we assume that f is
    # a valid XYZ file with no extension
fi
#echo "F=$f base=$base ext=$ext"

# molecule file to use in the computation
mol="$f"

# Check if it is a mol2
#   we need an XYZ input, if one exists, use it, 
#   otherwise make one.
#   $ext will be used to know the original file type
if [ "$ext" = "mol2" ] ; then 
    if [ -s $base.xyz ] ; then 
	if [ $VERBOSE -gt 1 ] ; then
            echo "  $ME: a file $base.xyz already exists"
            echo "  $ME: we will use the existing $base.xyz"
        fi
        f=$base.xyz 
    else
        if [ $VERBOSE -gt 1 ] ; then
            echo "  $ME: new file $base.xyz created"
	fi
        mol2toxyz $base.mol2
        f=$base.xyz
    fi
    # we cannot use directly a mol2 file, so we use the XYZ instead
    mol=$base.xyz
fi
#echo "F=$f base=$base ext=$ext"

# check if it is a dalton input file
#    all our routines have been prepared to work on XYZ
#    files, so we make one to work with
if [ "$ext" = "mol" -o "$ext" = "inp" ] ; then 
    if [ -s $base.xyz ] ; then 
	if [ $VERBOSE -gt 1 ] ; then
            echo "  $ME: a file $base.xyz already exists"
            echo "  $ME: we will use the existing $base.xyz"
        fi
        f=$base.xyz 
    else
        if [ $VERBOSE -gt 1 ] ; then
            echo "  $ME: new file $base.xyz created"
	fi
        dalton2xyz $base.$ext
        f=$base.xyz
    fi
fi
#echo "F=$f base=$base ext=$ext"

# the XYZ file to carry out pre- and post-processing
xyz=$f
name=$base

if [ -s "$f" ] ; then
    if [ "$BASIS" == "help" -o "$GUESS" == "help" ] ; then
        list_basis_sets $f
    fi
else
    echo "Error: molecule '$f' must exist!"
    if [ "$BASIS" == "help" -o "$GUESS" == "help" ] ; then
        list_basis_sets
    fi
    exit
fi


# Check if a large computation is taking place
#
# Number of atoms
natoms=$(wc -l < "$f")
natoms=$(( $natoms - 2))
# system dimensions (for computing box sizes)
dim=( `xyz_dimensions "$f"` )
vol=`bc -l <<< "${dim[0]} * ${dim[1]} * ${dim[2]}"`
if [ "$VERBOSE" -gt 0 ] ; then
    echo "N.atoms $natoms Nuclei dimensions (X Y Z) ${dim[@]} Å Nuclei vol $vol Å³"
fi


if [ $natoms -gt $LARGE_SYSTEM_SIZE ] ; then
    LARGE="yes"
fi
if [ "$LARGE" == "yes" ] ; then
    if [ -x $ERGO_HOME/bin/ergo-double ] ; then
        ERGOGUESS=$ERGO_HOME/bin/ergo-double
    else
	ERGOGUESS=$ERGO_HOME/bin/ergo
    fi
    if [ -x $ERGO_HOME/bin/ergo-long ] ; then
    	ERGOCALC=$ERGO_HOME/bin/ergo-long
    else
    	ERGOCALC=$ERGO_HOME/bin/ergo
    fi
    # This should be computed from the system dimensions
    FMMBOX=44
else
    # try to use the fastest version available (if possible)
    if [ -x $ERGO_HOME/bin/ergo-long ] ; then
    	ERGOCALC=$ERGO_HOME/bin/ergo-long
    elif [ -x $ERGO_HOME/bin/ergo-double ] ; then
        ERGOGUESS=$ERGO_HOME/bin/ergo-double
    elif [ -x $ERGO_HOME/bin/ergo-single ] ; then
        ERGOGUESS=$ERGO_HOME/bin/ergo-single
    else
	ERGOGUESS=$ERGO_HOME/bin/ergo
    fi
    FMMBOX=4.4
fi

# if a specific precision has been forcefully requested, try to use it
if [ "$PRECISION" != "default" ] ; then
    if [ -x $ERGO_HOME/bin/ergo-$PRECISION ] ; then
	ERGOGUESS=$ERGO_HOME/bin/ergo-$PRECISION
    	ERGOCALC=$ERGO_HOME/bin/ergo-$PRECISION
    else
        # Note that it is possible that the default precision
        # might be the same requested (without the name extension)
	ERGOGUESS=$ERGO_HOME/bin/ergo
    	ERGOCALC=$ERGO_HOME/bin/ergo
    fi
else
    ERGOGUESS=$ERGO_HOME/bin/ergo
    ERGOCALC=$ERGO_HOME/bin/ergo
fi

# Check if the precision finally selected is as requested:
selp=`$ERGOCALC -e precision`
# We have a problem in that long is reported as long_double, hence
# we must check for presence of the substring (##), and to avoid 
# double matching as well, we check for it at the beginning only
# ($PRECISION*). If the string is not found (null string, -z is
# true) then we notify the user.
if [ ! -z "${selp##$PRECISION*}" -a $PRECISION != "default" ] ; then 
    echo "WARNING: selected precision '$selp' different from requested '$PRECISION'"
fi
# if the system is large and the precision selected is not long_double,
#	(the user may have selected long but it may have not been found)
#	then, notify the user.
if [ "$LARGE" == "yes" -a "$selp" != "long_double" ] ; then
    echo "WARNING: ERGO executable precision may be too low:" `$ERGOCALC -e precision`
fi


#
# Check if we need to account for spin polarization
#	NOTE: These are TOO SIMPLE heuristics
#	DO NOT RELY ON THEM. YOU HAVE BEEN WARNED!!!
#
#$calc_elec $xyz
#nelec=`$calc_elec $xyz`
nelec=`calc_e $xyz`
nelec=$(( $nelec - $CHARGE ))
SPIN=$(($nelec %2))

if [ $VERBOSE -gt 0 ] ; then
    echo ""
    echo "$0 -i $FILE -c $CHARGE -g $GUESS -b $BASIS -r $RHF -u $UHF -l $LARGE -C $CI -v $VERBOSE -x $XC -p $PRECISION -a $ACCURACY -n $OMP_NUM_THREAD$"
    echo ""
fi
if [ $VERBOSE -gt 1 ] ; then
    echo ""
    echo "$0:"
    echo "    --input $FILE"
    echo "    --charge $CHARGE"
    echo "    --guess $GUESS"
    echo "    --basis $BASIS"
    echo "    --large $LARGE"
    echo "    --rhf $RHF"
    echo "    --uhf $UHF"
    echo "    --CI $CI"
    echo "    --XC $XC"
    echo "    --precision $PRECISION"
    echo "    --accuracy $ACCURACY"
    echo "    --num-threads $OMP_NUM_THREADS"
    echo ""
    echo "    NELEC = $nelec"
    echo "    SPIN = $SPIN"
    echo "    ERGOGUESS = $ERGOGUESS"
    echo "    ERGOCALC = $ERGOCALC"
    echo "    FMMBOX = $FMMBOX"
    echo "    VERBOSE = $VERBOSE"
    echo ""
fi

#
#	GO FOR IT
#

echo "Computing $name $GUESS $BASIS"

# Make a subdirectory for the computation
if [ -e $name ] ; then 
    if [ ! -d $name ] ; then
	echo " a file or directory named $name already exists"
	exit
    fi
else
    mkdir $name
fi
pushd `pwd` > /dev/null
cd $name

# link XYZ and molecule file into work subdir
if [ ! -e $xyz ] ; then ln -s ../$xyz . ; fi
if [ ! -e $mol ] ; then ln -s ../$mol . ; fi

#
#  Obtain initial guess
#

if [ "$GUESS" != "NONE" ] ; then
    # Make initial guess using requested basis
    if [ ! -e $name.$GUESS.density.bin ] ; then
        echo -n "  " ; date -u 
        echo "  getting starting guess with HF/$GUESS..."
        # I know. I do it this way to ensure we keep a copy of the
        # configuration used to run the calculation
        cat > $name.$GUESS.in <<END
            set_nthreads("detect")
            basis = "$GUESS";
            charge = $CHARGE;
            use_simple_starting_guess = 1;
            J_K.use_fmm = 1;
            J_K.threshold_2el_J = 1e-6;
            J_K.threshold_2el_K = 1e-6;
            #J_K.threshold_2el_J = 1e-6;
            #J_K.threshold_2el_K = 1e-6;
            J_K.fmm_box_size = $FMMBOX;
            scf.convergence_threshold = $ACCURACY;
            scf.output_homo_and_lumo_eigenvectors = 1;
            spin_polarization = $SPIN;
            scf.save_final_potential = 1;
            run "$METHOD";
END

        $ERGOGUESS -m $mol > /dev/null < $name.$GUESS.in

        echo -n "  " ; grep CONVERGED ergoscf.out
        if [ $? -ne 0 ] ; then echo "WARNING: COMPUTATION DID NOT CONVERGE!" ; fi

        if [ -e ergoscf.out ] ; then mv ergoscf.out $name.$GUESS.ergoscf ; fi
        if [ -e density.bin ] ; then mv density.bin $name.$GUESS.density.bin ; fi
        if [ -e overlap.bin ] ; then mv overlap.bin $name.$GUESS.overlap.bin ; fi
        if [ -e homo_coefficient_vec.txt ] ; then
            mv homo_coefficient_vec.txt $name.$GUESS.homo_coefficient_vec.txt
        fi
        if [ -e lumo_coefficient_vec.txt ] ; then
            mv lumo_coefficient_vec.txt $name.$GUESS.lumo_coefficient_vec.txt
        fi
        if [ -e gabeditfile.gab ] ; then
            mv gabeditfile.gab $name.$GUESS.homo_lumo.gab
        fi
    else
        echo "  ErgoSCF: reusing already existing HF/$GUESS..."
    fi
fi
#
# Refine calculation
#
if [ ! -e $name.$GUESS.$BASIS.ergoscf ] ; then
    if [ "$BASIS" == "NONE" ] ; then echo "Nothing else to do" ; exit ; fi
    if [ -e "$name.$GUESS.density.bin" ] ; then
        echo "  $ME: Using $name.$GUESS.density.bin as initial guess"
        INITIALGUESS="initial_density = \"$name.$GUESS.density.bin\";"
    else
        echo "  Using simple starting guess"
    	INITIALGUESS="use_simple_starting_guess = 1;"
    fi
    if [ "$METHOD" != "HF" ] ; then
    	DFTOPT="XC.sparse_mode=1; XC.radint=1e-10; XC.type=$XC"
    else
        DFTOPT=""
    fi
    echo -n "  " ; date -u
    echo "  running $METHOD/$BASIS..."
    cat > $name.$GUESS.$BASIS.in <<END
        set_nthreads("detect")
        $INITIALGUESS
        basis = "$BASIS"
        charge = $CHARGE
        do_ci_after_scf = $CI
        enable_memory_usage_output = 1
        spin_polarization = $SPIN
        output_basis = 1
        J_K.use_fmm = 1
        #J_K.threshold_2el_J = 1e-10
        #J_K.threshold_2el_K = 1e-10
        J_K.threshold_2el_J = $ACCURACY
        J_K.threshold_2el_K = $ACCURACY
        J_K.fmm_box_size = $FMMBOX
        J_K.exchange_box_size = $FMMBOX
        scf.calculation_identifier = "$name"
        scf.convergence_threshold = $ACCURACY
        scf.create_mtx_files_dipole = 1
        scf.create_mtx_files_D = 1
        scf.create_mtx_files_F = 1
        scf.create_mtx_file_S = 1
        scf.output_homo_and_lumo_eigenvectors = 1
        scf.force_restricted = $RHF
        scf.force_unrestricted = $UHF
        scf.save_final_potential = $RHF
        scf.output_mulliken_pop = 1
        scf.write_overlap_matrix = 1
        $DFTOPT
        run "$METHOD"
END

    $ERGOCALC -m $mol < $name.$GUESS.$BASIS.in > /dev/null
    
    echo -n "  " ; grep CONVERGED ergoscf.out
    if [ $? -ne 0 ] ; then echo "WARNING: COMPUTATION DID NOT CONVERGE!" ; fi

    if [ -e ergoscf.out ] ; then mv ergoscf.out $name.$GUESS.$BASIS.ergoscf ; fi
    if [ -e density.bin ] ; then mv density.bin $name.$GUESS.$BASIS.density.bin ; fi
    if [ -e overlap.bin ] ; then mv overlap.bin $name.$GUESS.$BASIS.overlap.bin ; fi
    if [ -e homo_coefficient_vec.txt ] ; then
        mv homo_coefficient_vec.txt $name.$GUESS.$BASIS.homo_coefficient_vec.txt
    fi
    if [ -e lumo_coefficient_vec.txt ] ; then
        mv lumo_coefficient_vec.txt $name.$GUESS.$BASIS.homo_coefficient_vec.txt
    fi
    if [ -e gabeditfile.gab ] ; then
        mv gabeditfile.gab $name.$GUESS.$BASIS.homo_lumo.gab
    fi
    
    grep 'INSC Mulliken charge of atom' $name.$GUESS.$BASIS.ergoscf | \
    	sed -e 's/INSC Mulliken charge of atom //g' | \
        tr -d '=' > $name.$GUESS.$BASIS.charges
    grep "INSC dipole_moment_" $name.$GUESS.$BASIS.ergoscf | \
        sed -e 's/INSC //g' > $name.$GUESS.$BASIS.dipole

    # make a mol2 file with the computed charges
    # if the original file was already in mol2 format we prefer to use
    # is as template (and avoid hypothetical problems with babel, which
    # might also not be available)
    if [ "$ext" == "mol2" ] ; then
        cp ../$name.mol2 $name.$GUESS.$BASIS.mol2
    else
        if [ -x "$babel" ] ; then
            $babel -ixyz $xyz -omol2 $name.$GUESS.$BASIS.mol2
        fi
    fi
    if [ -s $name.$GUESS.$BASIS.mol2 ] ; then
        if [ $VERBOSE -gt 0 ] ; then
          echo "  $ME: creating an updated $name/$name.$GUESS.$BASIS.mol2 file"
        fi
        # this takes a charges file in sync with a mol2 file and adds charges to it.
        if [ -s $name.$GUESS.$BASIS.charges ] ; then
            # we have Mulliken charges computed
            cat $name.$GUESS.$BASIS.charges | \
            while read i charge ; do
                i=$((i + 1))
                if [ $VERBOSE -gt 2 ] ; then
                echo "  i=$i chg=$charge"
                # we search for records with the structure of an atom record
                # but if any other record matches the same structure we'll 
                # mess everything up. CAVEAT EMPTOR.
                sed -E -n \
                  "/^\s*$i\s+[^\s]+\s+[0-9.-]+\s+[0-9.-]+\s+[0-9.-]+\s+[A-Za-z0-9\.]+\s+[0-9]+\s+[^\s]+\s+/p" $name.$GUESS.$BASIS.mol2
	    	#       num   atom     x          y          z          atom_type        molnum   molname  charge bit
		fi
                sed -E \
                  "/^\s*$i\s+[^\s]+\s+[0-9.-]+\s+[0-9.-]+\s+[0-9.-]+\s+[A-Za-z0-9\.]+\s+[0-9]+\s+[^\s]+\s+/ \
                 s/(^\s*$i\s+[^\s]+\s+[0-9.-]+\s+[0-9.-]+\s+[0-9.-]+\s+[A-Za-z0-9\.]+\s+[0-9]+\s+[^\s]+\s+).*/\1$charge/" \
		    $name.$GUESS.$BASIS.mol2 > tmpFile.mol2
                mv tmpFile.mol2 $name.$GUESS.$BASIS.mol2
		if [ $VERBOSE -gt 2 ] ; then
                sed -E -n \
                  "/^\s*$i\s+[^\s]+\s+[0-9.-]+\s+[0-9.-]+\s+[0-9.-]+\s+[A-Za-z0-9\.]+\s+[0-9]+\s+[^\s]+\s+/p" $name.$GUESS.$BASIS.mol2
		fi
            done
        fi

    fi

    echo -n "  " ; date -u
else
    echo "  existing calculation of HF/$BASIS already exists"
fi

popd > /dev/null	# get out of $molecule working directory (under molecule's location)

echo
echo $file Quantum Mechanics ground state calculation completed successfully!
echo

popd > /dev/null	# return to user's working directory

exit
