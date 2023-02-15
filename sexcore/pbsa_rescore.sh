#!/bin/bash
#
#   rescore docked poses using PB/SA

export PATH=/u/jr/contrib/dock6/bin:$PATH
export OE_LICENSE=/u/jr/contrib/openeye/lic/oe_license

if [ ! -d pbsa ] ; then mkdir pbsa ; fi
cd pbsa

cp ../../../sh/pbsa.in .

if [ ! -e params ] ; then ln -s ../params . ; fi
if [ ! -e receptor.mol2 ] ; then ln -s ../receptor.mol2 . ; fi

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

if [ ! -s pbsa_scored.mol2 ] ; then
    dock6.pbsa -i pbsa.in -o pbsa.out -v
fi
cd ..

exit

#### this is ignored ###
#### this is pbsa.in ###
ligand_atom_file                                             docked.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                no
use_internal_energy                                          no
flexible_ligand                                              no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
contact_score_secondary                                      no
grid_score_primary                                           no
grid_score_secondary                                         no
dock3.5_score_primary                                        no
dock3.5_score_secondary                                      no
continuous_score_primary                                     no
continuous_score_secondary                                   no
gbsa_zou_score_primary                                       no
gbsa_zou_score_secondary                                     no
gbsa_hawkins_score_primary                                   no
gbsa_hawkins_score_secondary                                 no
pbsa_score_primary                                           yes
pbsa_score_secondary                                         no
pbsa_receptor_filename                                       receptor.mol2
pbsa_interior_dielectric                                     2.0
pbsa_exterior_dielectric                                     78.5
pbsa_vdw_grid_prefix                                         solvent_grid
amber_score_secondary                                        no
minimize_ligand                                              yes
atom_model                                                   all
vdw_defn_file                                                ./params/vdw_AMBER_parm99.defn
flex_defn_file                                               ./params/flex.defn
flex_drive_file                                              ./params/flex_drive.tbl
ligand_outfile_prefix                                        pbsa
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
