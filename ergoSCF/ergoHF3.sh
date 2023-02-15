#!/bin/bash

export PATH=$HOME/contrib/ergoSCF/bin:$PATH

guess='STO-2G'
medium='STO-3G'
final='STO-6G'
#final='Ahlrichs-pVDZ'

xyz=`basename $1`
name=`basename $xyz .xyz`

echo
echo "Computing $1 HF/$guess + HF/$final"

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

guess_input="
basis = \"$guess\";
use_simple_starting_guess=1;
J_K.use_fmm = 1;
J_K.threshold_2el_J = 1e-5;
J_K.threshold_2el_K = 1e-5;
J_K.fmm_box_size = 4.4;
scf.convergence_threshold = 1e-2;
cf.output_homo_and_lumo_eigenvectors = 1
#run \"HF\";
"
if [ ! -e $name.$guess.density.bin ] ; then
  echo "  getting starting guess with $guess ..."
  date -u 
  echo $guess_input | ergo -m $xyz > /dev/null
  date -u
  mv ergoscf.out $name.$guess.ergoscf
  if [ ! -e density.bin ] ; then echo "FAILED $guess" ; exit ; fi
  mv density.bin $name.$guess.density.bin
  mv gabeditfile.gab $name.$guess.gabeditfile.gab
  mv homo_coefficient_vec.txt $name.$guess.homo_coefficient_vec.txt
  mv lumo_coefficient_vec.txt $name.$guess.lumo_coefficient_vec.txt
fi

if [ ! -e $name.$medium.density.bin ] ; then
  echo "  running HF/$medium..."
  date -u
  ergo -m $1 <<EOINPUT > /dev/null
    initial_density = "$name.$guess.density.bin"
    basis = "$medium"
    #charge = 0
    enable_memory_usage_output = 1
    J_K.use_fmm = 1
    J_K.threshold_2el_J = 1e-6
    J_K.threshold_2el_K = 1e-6
    J_K.fmm_box_size = 3.3
    scf.calculation_identifier="$name"
    scf.convergence_threshold = 1e-5
    scf.output_homo_and_lumo_eigenvectors = 1
    scf.save_final_potential = 1
    scf.output_mulliken_pop = 1
    scf.write_overlap_matrix = 1
    run "HF"
EOINPUT
  date -u
  mv ergoscf.out $name.$medium.ergoscf
  if [ ! -e density.bin ] ; then echo "FAILED $medium" ; exit ; fi
  mv density.bin $name.$medium.density.bin
  mv overlap.bin $name.$medium.overlap.bin
  mv potential.bin $name.$medium.potential.bin
  mv gabeditfile.gab $name.$medium.gabeditfile.gab
  mv homo_coefficient_vec.txt $name.$medium.homo_coefficient_vec.txt
  mv lumo_coefficient_vec.txt $name.$medium.lumo_coefficient_vec.txt
fi

if [ ! -e $name.$final. ] ; then
  echo "  running HF/$final..."
  date -u
  ergo -m $1 <<EOINPUT > /dev/null
    initial_density = "$name.$medium.density.bin"
    basis = "$final"
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

  date -u
  grep CONVERGED ergoscf.out

  mv ergoscf.out $name.$final.ergoscf
  if [ ! -e density.bin ] ; then echo "FAILED $final" ; exit ; fi
  mv density.bin $name.$final.density.bin
  mv overlap.bin $name.$final.overlap.bin
  mv potential.bin $name.$final.potential.bin
  mv gabeditfile.gab $name.$final.gabeditfile.gab
  mv homo_coefficient_vec.txt $name.$final.homo_coefficient_vec.txt
  mv lumo_coefficient_vec.txt $name.$final.lumo_coefficient_vec.txt

fi

cd ..

echo
echo "$1 Hartree-Fock calculation completed successfully!"
echo

popd

exit
