#!/bin/bash
#
#	(C) 2013, Jose R Valverde. CNB/CSIC

# we need extended globs for testing for integers
shopt -s extglob

calc_e="python $HOME/contrib/jr/calc_e-.py"
#calc_e="python $HOME/Quantum/python/calc_e-.py"

export ERGO_HOME=$HOME/contrib/ergoSCF
#export ERGO_HOME=/opt/quantum/ergoSCF

export PATH=$ERGO_HOME/bin:$PATH


function usage {
    echo ""
    echo "$0: Carry out a ground-state HF calculation using ergoSCF"
    echo ""
    echo "Usage:"
    echo "    $0 -i file -c charge -g basis -b basis -l -r -u -C -h -m method -x XCtype"
    echo ""
    echo "    $0 --input file --charge charge --guess basis --basis basis "
    echo "       --large --rhf --uhf --CI --help --method method"
    echo ""
    echo "    -i --input	an XYZ file name"
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
    echo "    -p --precision    force a given precision in the calculation"
    echo "                      (one of 'single', 'double' or 'long')"
    echo ""
    echo "In case of conflicting options the last one will be used"
    echo ""
    exit
}

function is_int() {
#    return $(test "$@" -eq "$@" > /dev/null 2>&1)
#    if [[ $@ == [0-9]* ]] ; return 1 ; fi
    if [[ $@ =~ ^-?\+?[0-9]+$ ]] ; then return 1 ; fi
}

function list_basis_sets() {
    ls -C $ERGO_HOME/share/ergo/basis | grep -v Makefile | less
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
    echo "    BHANDHLYP Half-and-half functional combining HF, LSDA, Becke88 andLYP"
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

# default values
MOL="input.xyz"
CHARGE=0
GUESS="NOGUESS"
BASIS="STO-6G"
LARGE="no"
RHF=0
UHF=0
CI=0
SPIN=0
VERBOSE=0
METHOD="HF"
XC="HICU"
PRECISION=default

# Parse the command line
# ----------------------
# Note that we use `"$@"' to let each command-line parameter expand to a 
# separate word. The quotes around `$@' are essential!
# We need TEMP as the `eval set --' would nuke the return value of getopt.
TEMP=`getopt -o hi:c:b:g:m:x:lruCvp: \
     --long help,input:,charge:,basis:,guess:,method:,XC:,large,rhf,uhf,CI,verbose,precision: \
     -n "$0" -- "$@"`

# an invalid option was given
if [ $? != 0 ] ; then usage >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
        case "$1" in
                -h|--help) 
                    usage ;shift ;;

                -i|--input) 
                    #echo "INPUT FILE \`$2'" 
                    FILE=$2 ; shift 2 ;;
                    
                -c|--charge)
                    # if $2 is a positive number, use it, ignore otherwise
                    if [[ $2 =~ ^-?\+?[0-9]+$ ]] ; then CHARGE=$2 ; fi
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

                --) shift ; break ;;
                *) echo "Internal error!" >&2 ; usage ; exit 1 ;;
        esac
done


if [ "$BASIS" == "help" ] ; then
    list_basis_sets
fi

if [ "$METHOD" == "help" ] ; then
    list_methods
fi

if [ "$XC" == "help" ] ; then
    list_xctype
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

# get file directory
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
if [ "$ext" == "$f" ] ; then ext="xyz" ; f=$f.xyz ;  fi

if [ ! -e $f ] ; then echo "Error: molecule '$file'(.xyz) must exist!" >&2; exit 1 ; fi

xyz=$f
name=$base

# Check if a large computation is taking place
#
natoms=$(wc -l < $f)
natoms=$(( $natoms - 2))
if [ $natoms -gt 500 ] ; then
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
    if [ `$ERGOCALC -e precision` != "long" ] ; then
    	echo "WARNING: ERGO executable precision may be too low:" `$ERGOCALC -m precision`
    fi
    # This should be computed from the system dimensions
    FMMBOX=44
else
    # try to use the fastest versiona vailable (if possible)
    if [ -x $ERGO_HOME/bin/ergo-single ] ; then
        ERGOGUESS=$ERGO_HOME/bin/ergo-single
    else
	ERGOGUESS=$ERGO_HOME/bin/ergo
    fi
    if [ -x $ERGO_HOME/bin/ergo-double ] ; then
    	ERGOCALC=$ERGO_HOME/bin/ergo-double
    else
    	ERGOCALC=$ERGO_HOME/bin/ergo
    fi
    FMMBOX=4.4
fi

# NOTE that this will override values set by LARGE
if [ "$PRECISION" != "default" ] ; then
   ERGOGUESS=$ERGO_HOME/bin/ergo-$PRECISION
   ERGOCALC=$ERGO_HOME/bin/ergo-$PRECISION
fi
#
# Check if we need to account for spin polarization
#	NOTE: These are TOO SIMPLE heuristics
#	DO NOT RELY ON THEM. YOU HAVE BEEN WARNED!!!
#
#$calc_e $xyz
nelec=`$calc_e $xyz`
nelec=$(( $nelec - $CHARGE ))
SPIN=$(($nelec %2))

if [ $VERBOSE -eq 1 ] ; then
    echo "$0 -i $FILE -c $CHARGE -g $GUESS -b $BASIS -r $RHF -u $UHF -l $LARGE -C $CI"
elif [ $VERBOSE -gt 1 ] ; then
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
    echo ""
    echo "    NELEC = $nelec"
    echo "    SPIN = $SPIN"
    echo "    ERGOGUESS = $ERGOGUESS"
    echo "    ERGOCALC = $ERGOCALC"
    echo "    FMMBOX = $FMMBOX"
    echo ""
fi

#
#	GO FOR IT
#

echo "Computing $name $GUESS $BASIS"

# Make a subdirectory for the computation
if [ -e $name ] ; then 
    if [ ! -d $name ] ; then
	echo " a file named $name already exists"
	exit
    fi
else
    mkdir $name
fi
pushd `pwd` > /dev/null
cd $name

#
#  Obtain initial guess
#

# link original XYZ file into work subdir
if [ ! -e $xyz ] ; then ln -s ../$xyz . ; fi

if [ "$GUESS" != "NOGUESS" ] ; then
    # Make initial guess using requested basis
    if [ ! -e $name.$GUESS.density.bin ] ; then
        echo -n "  " ; date -u 
        echo "  getting starting guess with HF/$GUESS..."
        cat > $name.$GUESS.in <<END
            basis = "$GUESS";
            charge = $CHARGE;
            use_simple_starting_guess = 1;
            J_K.use_fmm = 1;
            J_K.threshold_2el_J = 1e-6;
            J_K.threshold_2el_K = 1e-6;
            J_K.fmm_box_size = $FMMBOX;
            scf.convergence_threshold = 1e-2;
            scf.output_homo_and_lumo_eigenvectors = 1;
            spin_polarization = $SPIN;
            scf.save_final_potential = 1;
            run "$METHOD";
END

        $ERGOGUESS -m $xyz > /dev/null < $name.$GUESS.in

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
        echo "  reusing already existing HF/$GUESS..."
    fi
fi
#
# Refine calculation
#

if [ ! -e $name.$GUESS.$BASIS.ergoscf ] ; then
    if [ "$BASIS" == "NONE" ] ; then echo "Nothing else to do" ; exit ; fi
    if [ -e "$name.$GUESS.density.bin" ] ; then
        echo "  Using $name.$GUESS.density.bin as initial guess"
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
    echo "  running HF/$BASIS..."
    cat > $name.$GUESS.$BASIS.in <<END
        $INITIALGUESS
        basis = "$BASIS"
        charge = $CHARGE
        do_ci_after_scf = $CI
        enable_memory_usage_output = 1
        spin_polarization = $SPIN
        output_basis = 1
        J_K.use_fmm = 1
        J_K.threshold_2el_J = 1e-10
        J_K.threshold_2el_K = 1e-10
        J_K.fmm_box_size = $FMMBOX
        J_K.exchange_box_size = $FMMBOX
        scf.calculation_identifier = "$name"
        scf.convergence_threshold = 1e-5
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

    $ERGOCALC -m $xyz < $name.$GUESS.$BASIS.in > /dev/null

    echo -n "  " ; grep CONVERGED ergoscf.out

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

    echo -n "  " ; date -u
else
    echo "  existing calculation of HF/$BASIS already exists"
fi

popd > /dev/null

echo
echo $file Hartree-Fock calculation completed successfully!
echo

popd > /dev/null

exit
