#!/bin/bash

#for j in 8ogtp oxg gn gtp Mg8OGTP-- MgGTP-- ; do
for j in 8ogtp gtp Mg8OGTP-- MgGTP-- ; do
    cd $j
#    for i in * ; do
    for i in rhl.A ; do
	if [ -e flex-grid-gbsa.out ] ; then continue ; fi
        cd $i
        cat > flex-grid-gbsa.in <<END
ligand_atom_file                                             ./ligand.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                yes
automated_matching                                           yes
receptor_site_file                                           ./rec_site.sph
max_orientations                                             500
critical_points                                              no
chemical_matching                                            no
use_ligand_spheres                                           no
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
flexible_ligand                                              yes
min_anchor_size                                              40
pruning_use_clustering                                       yes
pruning_max_orients                                          100
pruning_clustering_cutoff                                    100
pruning_conformer_score_cutoff                               25.0
use_clash_overlap                                            no
write_growth_tree                                            no
bump_filter                                                  no
score_molecules                                              yes
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
gbsa_zou_score_secondary                                     no
gbsa_hawkins_score_primary				     no
gbsa_hawkins_score_secondary                                 yes
gbsa_hawkins_score_rec_filename				     receptor.mol2
gbsa_hawkins_score_solvent_dielectric			     78.5
gbsa_hawkins_use_salt_screen       			     no
gbsa_hawkins_score_gb_offset				     0.09
gbsa_hawkins_score_cont_vdw_and_es                           yes
gbsa_hawkins_score_vdw_att_exp				     6
gbsa_hawkins_score_vdw_rep_exp				     12
grid_score_rep_rad_scale				     1.0
amber_score_secondary                                        no
minimize_ligand                                              yes
minimize_anchor                                              yes
minimize_flexible_growth                                     yes
use_advanced_simplex_parameters                              no
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
simplex_anchor_max_iterations                                500
simplex_grow_max_iterations                                  500
simplex_grow_tors_premin_iterations                          0
simplex_random_seed                                          0
simplex_restraint_min                                        no
atom_model                                                   all
vdw_defn_file                                                $HOME/dock6/parameters/vdw_AMBER_parm99.defn
flex_defn_file                                               $HOME/dock6/parameters/flex.defn
flex_drive_file                                              $HOME/dock6/parameters/flex_drive.tbl
ligand_outfile_prefix                                        flex-grid-gbsa
write_orientations                                           yes
num_scored_conformers                                        100
write_conformations					     no
cluster_conformations                                        yes
cluster_rmsd_threshold                                       2.0
rank_ligands                                                 no

END
#   this works for most cases in FINISTERRAE
#	qsub -N FDOCK6-$j-$i -l num_proc=1,s_rt=20:00:00,s_vmem=2G,h_fsize=1G <<ENDSUB
#   try with more memory for big grid files
#	qsub -N FOCK6-$j-$i -l num_proc=1,s_rt=20:00:00,s_vmem=4G,h_fsize=1G <<ENDSUB
#   1dg3 requires 4GB memory (from NGS, an x86_64 machine)
#	qsub -l num_proc=1,s_rt=20:00:00,s_vmem=4G,h_fsize=1G <<ENDSUB
#    this should work on NGS
	qsub -q slow -N DOCK6+$j-$i \
	     -e $HOME/work/arrojas/dock6/$j/$i/DOCK6+.err \
	     -o $HOME/work/arrojas/dock6/$j/$i/DOCK6+.out <<ENDSUB
    	    cd $HOME/work/arrojas/dock6/$j/$i
	    export PATH=$HOME/dock6/bin:$PATH
	    export DELPHI_HOME=$HOME/bin/delphi
	    dock6 -i flex-grid-gbsa.in -o flex-grid-gbsa.out -v
ENDSUB
    cd ..
    done
    cd ..
done
