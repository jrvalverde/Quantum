#!/bin/bash
#   usage: ergoHF+.sh [infile.xyz] [refine] [initial-guess]
#   	all arguments are optional
#   	if infile == "-h", print help
#

# configuration for local ergoSCF
#
#export ERGO_HOME=/opt/quantum/ergoSCF
export ERGO_HOME=$HOME/contrib/ergoSCF

export PATH=$ERGO_HOME/bin:$PATH

# process command line
f=${1:-"input.xyz"}
xyz=`basename $f`
name=`basename $xyz .xyz`
initial_basis=${3:-"STO-3G"}
refined_basis=${2:-"aug-cc-pVDZ"}

#echo $f
#echo $refined_basis
#echo $initial_basis

if [ $f == '-h' ] ; then
    echo "usage: ergoHF+.sh [infile.xyz] [refine] [initial-guess]"
    echo "  all arguments are optional, defaults are"
    echo "  	ergoHF+.sh input.xyz aug-cc-pVDZ STO-3G"
    echo "  	ergoHF+.sh -h prints this help"
    echo "  	ergoHF+.sh -l lists available basis sets"
    echo "  	ergoHF+.sh -H prints ergoSCF help"
    exit
fi

if [ $f == '-l' ] ; then
    echo "LIST OF AVAILABLE BASIS SETS"
    echo "----------------------------"
    echo ""
    ls $ERGO_HOME/basis/
    echo ""
    exit
fi

if [ $f == '-H' ] ; then
    ergo -h
    rm ergoscf.out
    exit
fi

# do the work
#

#unused
guess_input='
basis = "STO-3G";
use_simple_starting_guess=1;
J_K.use_fmm = 1;
J_K.threshold_2el_J = 1e-6;
J_K.threshold_2el_K = 1e-6;
J_K.fmm_box_size = 4.4;
scf.convergence_threshold = 1e-2;
scf.output_mulliken_pop = 1;
scf.save_final_potential = 1;
scf.output_homo_and_lumo_eigenvectors = 1;
run "HF";
'

echo

echo "Computing $1 HF/$initial_basis + $refined_basis"

pushd `pwd` > /dev/null
cd `dirname $1`

if [ -e $name.$refined_basis ] ; then 
    if [ ! -d $name.$refined_basus ] ; then
	echo " a file named $name.$refined_basis already exists"
	exit
    fi
else
	mkdir $name.$refined_basis
fi
cd $name.$refined_basis

if [ ! -e $xyz ] ; then ln -s ../$xyz . ; fi

if [ ! -e $name.$initial_basis.density.bin ] ; then
  date -u 
  echo "  getting starting guess with STO-3G..."
  ergo -m $xyz > /dev/null <<END
	basis = "$initial_basis";
	use_simple_starting_guess=1;
	J_K.use_fmm = 1;
	J_K.threshold_2el_J = 1e-6;
	J_K.threshold_2el_K = 1e-6;
	J_K.fmm_box_size = 4.4;
	scf.convergence_threshold = 1e-2;
    	scf.output_mulliken_pop = 1;
    	scf.save_final_potential = 1;
    	scf.output_homo_and_lumo_eigenvectors = 1;
	run "HF";
END
  if [ -e ergoscf.out ] ; then mv ergoscf.out $name.$initial_basis.ergoscf ; fi
  if [ -e density.bin ] ; then mv density.bin $name.$initial_basis.density.bin ; fi
  if [ -e gabeditfile.gab ] ; then mv gabeditfile.gab $name.$initial_basis.homo_lumo.gab ; fi
fi

if [ ! -e $name.$refined_basis.ergoscf ] ; then
    date -u
    echo "  running HF-CI/$refined_basis"
    ergo -m $xyz <<EOINPUT > /dev/null
	initial_density = "$name.$initial_basis.density.bin"
	basis = "$refined_basis"
	#extra_charges_atom_charge_h = 0.41
	#extra_charges_atom_charge_o = -0.82
	charge = 0
	do_ci_after_scf = 1
	enable_memory_usage_output = 1
	#spin_polarization = 0
	#output_basis = 0
	#use_6_d_functions = 0
	J_K.use_fmm = 1
#	J_K.threshold_2el_J = 1e-10
#	J_K.threshold_2el_K = 1e-10
	J_K.threshold_2el_J = 1e-6
	J_K.threshold_2el_K = 1e-6
	J_K.fmm_box_size = 3.3
	scf.calculation_identifier="$name"
	scf.convergence_threshold = 1e-4
	scf.create_mtx_files_dipole = 1
	scf.create_mtx_files_D = 1
	scf.create_mtx_files_F = 1
	scf.create_mtx_file_S = 1
	scf.output_homo_and_lumo_eigenvectors = 1
	#scf.electric_field_x = 0
	#scf.electric_field_y = 0
	#scf.electric_field_z = 0
	#scf.electronic_temperature = 0
	#scf.force_restricted = 0
	#scf.force_unrestricted = 0
	#scf.do_electron_dynamics = 0
	scf.save_final_potential = 1
	scf.output_mulliken_pop = 1
	scf.write_overlap_matrix = 1
	run "HF"
EOINPUT

    grep CONVERGED ergoscf.out

    if [ -e ergoscf.out ] ; then 
    	mv ergoscf.out $name.$refined_basis.ergoscf
    fi
    if [ -e density.bin ] ; then 
    	mv density.bin $name.$refined_basis.density.bin 
    fi
    if [ -e gabeditfile.gab ; then
    	mv gabeditfile.gab $name.$refined_basis.homo_lumo.gab
    fi

    date -u
fi

cd ..

echo
echo $1 Hartree-Fock calculation completed successfully!
echo

popd

exit
