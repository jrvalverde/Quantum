#!/bin/bash

export PATH=$HOME/contrib/ergoSCF/bin:$PATH

xyz=`basename $1`
name=`basename $xyz .xyz`

guess_input='
basis = "STO-2G";
use_simple_starting_guess=1;
J_K.use_fmm = 1;
J_K.threshold_2el_J = 1e-6;
J_K.threshold_2el_K = 1e-6;
J_K.fmm_box_size = 4.4;
scf.convergence_threshold = 1e-2;
run "HF";
'

echo

echo "Computing $1 HF/6-31G**"

pushd `pwd` > /dev/null
cd `dirname $1`

if [ -e $name ] ; then 
    if [ ! -d $name ] ; then
	echo " a file named $name already exists"
	exit
    fi
else
	mkdir $name
fi
cd $name

if [ ! -e $xyz ] ; then ln -s ../$xyz . ; fi

if [ ! -e $name.sto2g.density.bin ] ; then
  date -u 
  echo "  getting starting guess with STO-2G..."
  echo $guess_input | ergo -m $xyz > /dev/null
  mv ergoscf.out $name.sto2g.ergoscf
  mv density.bin $name.sto2g.density.bin
fi

if [ ! -e $name.631gss.ergoscf ] ; then
date -u
echo "  running HF/6-31Gss..."
ergo -m $1 <<EOINPUT > /dev/null
initial_density = "$name.sto2g.density.bin"
basis = "6-31Gss"
#extra_charges_atom_charge_h = 0.41
#extra_charges_atom_charge_o = -0.82
#charge = 0
#do_ci_after_scf = 0
enable_memory_usage_output = 1
#spin_polarization = 0
#output_basis = 0
#use_6_d_functions = 0
J_K.use_fmm = 1
J_K.threshold_2el_J = 1e-10
J_K.threshold_2el_K = 1e-10
J_K.fmm_box_size = 3.3
scf.calculation_identifier="$name"
scf.convergence_threshold = 1e-5
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

mv ergoscf.out $name.631gss.ergoscf
if [ -e density.bin ] ; then mv density.bin $name.631gss.density.bin ; fi

date -u
fi

cd ..

echo
echo $1 Hartree-Fock calculation completed successfully!
echo

popd

exit
