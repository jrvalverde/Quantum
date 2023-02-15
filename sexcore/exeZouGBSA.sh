#!/bin/bash

SN='1'

for i in 8ogtp gtp Mg8OGTP-- MgGTP-- ; do
#for i in Mg8OGTP-- MgGTP-- ; do
#for i in 8ogtp gtp ; do
    cd $i
    for j in * ; do
	cd $j
	echo Preparing $i/$j
    	if [ ! -h receptor_box.pdb ] ; then
	    ln -s ../../receptor/$j/receptor_box.pdb .
    	fi
	if [ ! -h receptor.pdb ] ; then
	    ln -s ../../receptor/$j/$j.pdb receptor.pdb
    	fi
	if [ ! -h params ] ; then
	    ln -s /u/jr/contrib/dock6/parameters params
    	fi
        if [ ! -e solvent_grid.nrg ] ; then 
	    # Calculate grids for Hawkins GB/SA and Van der Waals
	    cat > solvent_grid.in <<END
compute_grids                  yes
grid_spacing                   0.3
output_molecule                no
contact_score                  no
energy_score                   yes
energy_cutoff_distance         9999
atom_model                     a
attractive_exponent            6
repulsive_exponent             12
distance_dielectric            no 
dielectric_factor              1 
bump_filter                    yes
bump_overlap                   0.75
receptor_file                  ligand.mol2
box_file                       receptor_box.pdb
vdw_definition_file            ./params/vdw_AMBER_parm99.defn
score_grid_prefix              solvent_grid
END
	    grid -i solvent_grid.in
	fi
	# Compute Zou GB/SA grids
	if [ ! -e nchemgrid_GB/gbsa_zou_grid.vdw ] ; then
	    mkdir -p nchemgrid_GB
	    cd nchemgrid_GB
	    touch cavity.pdb
	    cat > INCHEM<<END
../receptor.pdb
cavity.pdb
../params/prot.table.ambcrg.ambH
../params/vdw.parms.amb
../receptor_box.pdb
0.3
2
1
8.0 8.0
78.3 78.3
2.3 2.8
gbsa_zou_grid
1
END
	    nchemgrid_GB
	    if [ ! -e gbsa_zou_grid.vdw ] ; then nchemgrid_GB_big ; fi
	    cd ..
	fi
	if [ ! -e nchemgrid_SA/gbsa_zou_grid.sas ] ; then
	    mkdir -p nchemgrid_SA
	    cd nchemgrid_SA
	    cat > INCHEM<<END
../receptor.pdb
../params/prot.table.ambcrg.ambH
../params/vdw.parms.amb
../receptor_box.pdb
0.3
1.4
2
8.0
gbsa_zou_grid
END
	    nchemgrid_SA
	    if [ ! -e gbsa_zou_grid.sas ] ; then nchemgrid_SA_big ; fi
	    cd ..
	fi
	# if the default approach fails, try increasing grid step
	if [ ! -e nchemgrid_GB/gbsa_zou_grid.vdw -o \
	     ! -e nchemgrid_SA/gbsa_zou_grid.sas ] ; then
	    cd nchemgrid_GB
	    mv INCHEM INCHEM.03
	    sed INCHEM.03 -e 's/^0.3/0.5/g' > INCHEM
	    nchemgrid_GB_big 
	    cd ../nchemgrid_SA
	    mv INCHEM INCHEM.03
	    sed INCHEM.03 -e 's/^0.3/0.5/g' > INCHEM
	    nchemgrid_SA_big 
	    cd ..
	fi

	if [ ! -e nchemgrid_GB/gbsa_zou_grid.vdw -o \
	     ! -e nchemgrid_SA/gbsa_zou_grid.sas ] ; then
	    echo "ERROR PROCESSING GB/SA GRIDS FOR $i/$j"
	fi

	cd ..
    done
    cd ..
done


for j in 8ogtp gtp Mg8OGTP-- MgGTP-- ; do
#for j in Mg8OGTP-- MgGTP-- ; do
#for j in 8ogtp gtp ; do
    cd $j
    for i in * ; do
        cd $i
	if [ -e flex-ZouGBSA-$SN.out ] ; then cd .. ; continue ; fi
	echo ""
    	echo DOCKING $j/$i
        cat > flex-ZouGBSA-$SN.in <<END
ligand_atom_file                                             ./ligand.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                yes
automated_matching                                           yes
receptor_site_file                                           ./rec_site.sph
max_orientations                                             1000
critical_points                                              no
chemical_matching                                            no
use_ligand_spheres                                           no
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
flexible_ligand                                              yes
min_anchor_size                                              40
pruning_use_clustering                                       yes
pruning_max_orients                                          1000
pruning_clustering_cutoff                                    1000
pruning_conformer_score_cutoff                               1000
use_clash_overlap                                            no
write_growth_tree                                            no
bump_filter                                                  yes
score_molecules                                              yes
continuous_score_primary                                     no
contact_score_primary                                        no
contact_score_secondary                                      no
grid_score_primary                                           yes
grid_score_secondary                                         no
grid_score_rep_rad_scale				     1.0
grid_score_vdw_scale                                         1
grid_score_es_scale                                          1
grid_score_grid_prefix                                       ./grid
dock3.5_score_primary                                        no
dock3.5_score_secondary                                      no
dock3.5_vdw_score					     yes
dock3.5_grd_prefix					     chem52
dock3.5_electrostatic_score				     yes
dock3.5_ligand_internal_energy				     yes
dock3.5_ligand_desolvation_score			     volume
dock3.5_write_atomic_energy_contrib			     yes
dock3.5_score_vdw_scale					     1.0
dock3.5_score_es_scale					     1.0
continuous_score_secondary                                   no
gbsa_zou_score_primary                                       no
gbsa_zou_score_secondary                                     yes
gbsa_zou_gb_grid_prefix                                      ./nchemgrid_GB/gbsa_zou_grid
gbsa_zou_sa_grid_prefix                                      ./nchemgrid_SA/gbsa_zou_grid
gbsa_zou_vdw_grid_prefix                                     ./solvent_grid
gbsa_zou_screen_file                                         ./params/screen.in
gbsa_zou_solvent_dielectric                                  78.300003
gbsa_hawkins_score_primary				     no
gbsa_hawkins_score_secondary                                 no
gbsa_hawkins_score_rec_filename				     receptor.mol2
gbsa_hawkins_score_solvent_dielectric			     78.5
gbsa_hawkins_use_salt_screen       			     no
gbsa_hawkins_score_gb_offset				     0.09
gbsa_hawkins_score_cont_vdw_and_es                           yes
gbsa_hawkins_score_vdw_att_exp				     6
gbsa_hawkins_score_vdw_rep_exp				     12
amber_score_secondary                                        no
minimize_ligand                                              yes
minimize_anchor                                              yes
minimize_flexible_growth                                     yes
use_advanced_simplex_parameters                              yes
simplex_max_cycles                                           10
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
#simplex_anchor_max_iterations                                500
#simplex_grow_tors_premin_iterations                          20
#simplex_grow_max_iterations                                  20
simplex_random_seed                                          $SN
simplex_restraint_min                                        no
simplex_secondary_minimize_pose     	    	    	     yes
use_advanced_secondary_simplex_parameters                    no
simplex_anchor_max_cycles                                    10
simplex_anchor_score_converge                                0.1
simplex_anchor_cycle_converge	    	    	             1.0
simplex_anchor_trans_step                                    1.0
simplex_anchor_rot_step     	    	    	    	     0.1
simplex_anchor_tors_step                                     10.0
simplex_grow_max_cycles                                      2
simplex_grow_score_converge                                  0.1
simplex_grow_cycle_converge                                  1.0
simplex_grow_trans_step                                      1.0
simplex_grow_rot_step                                        0.1
simplex_grow_tors_step                                       10.0
simplex_secondary_max_cycles                                 10
simplex_secondary_max_iterations                             100
atom_model                                                   all
vdw_defn_file                                                ./params/vdw_AMBER_parm99.defn
flex_defn_file                                               ./params/flex.defn
flex_drive_file                                              ./params/flex_drive.tbl
ligand_outfile_prefix                                        flex-ZouGBSA-$SN
write_orientations                                           no
write_conformations					     yes
num_scored_conformers                                        500
num_primary_scored_conformers_rescored	    	    	     500
num_secondary_scored_conformers     	    	    	     500
write_primary_conformations                                  yes
write_secondary_conformations                                yes
cluster_conformations                                        no
cluster_rmsd_threshold                                       2.0
cluster_primary_conformations                                no
cluster_secondary_conformations                              no
num_clusterheads_for_rescore                                 100
rank_ligands                                                 no
rank_primary_ligands                                         no
max_primary_ranked                                           500
rank_secondary_ligands                                       no
max_secondary_ranked                                         500
END
#   this works for most cases in FINISTERRAE
#	qsub -N FDOCK6-$j-$i -l num_proc=1,s_rt=20:00:00,s_vmem=2G,h_fsize=1G <<ENDSUB
#   try with more memory for big grid files
#	qsub -N FOCK6-$j-$i -l num_proc=1,s_rt=20:00:00,s_vmem=4G,h_fsize=1G <<ENDSUB
#   1dg3 requires 4GB memory (from NGS, an x86_64 machine)
#	qsub -l num_proc=1,s_rt=20:00:00,s_vmem=4G,h_fsize=1G <<ENDSUB
#    this should work on NGS
#	qsub -q slow -N DOCK6+$j-$i \
#	     -e $HOME/work/arrojas/dock6/$j/$i/DOCK6+.err \
#	     -o $HOME/work/arrojas/dock6/$j/$i/DOCK6+.out <<ENDSUB
#    	    cd $HOME/work/arrojas/dock6/$j/$i
	    export PATH=$HOME/contrib/dock6/bin:$PATH
	    export DELPHI_HOME=$HOME/bin/delphi
#	    dock6 -i flex-ZouGBSA-$SN.in -o flex-ZouGBSA-$SN.out -v &
	    dock6 -i flex-ZouGBSA-$SN.in -o flex-ZouGBSA-$SN.out -v 
	echo $j/$i DONE
    cd ..
    done
    cd ..
done
