#!/bin/bash
#SBATCH --job-name=af-2.3.2         # job name
#SBATCH --time=2-00:00:00           # max job run time dd-hh:mm:ss
#SBATCH --ntasks-per-node=1         # tasks (commands) per compute node
#SBATCH --cpus-per-task=24          # CPUs (threads) per command
#SBATCH --mem=122G                  # total memory per node
#SBATCH --gres=gpu:h100:1           # request one GPU
#SBATCH --output=stdout.%x.%j       # save stdout to file
#SBATCH --error=stderr.%x.%j        # save stderr to file

<<README
    - AlphaFold: https://github.com/deepmind/alphafold
    - AlphaPickle: https://github.com/mattarnoldbio/alphapickle
    - HPRC AlphaFold: https://hprc.tamu.edu/kb/Software/AlphaFold
README

######### SYNOPSIS #########
# this script will run AlphaFold on the specified VARIABLES and graph .pkl files
# currently AlphaFold supports running on only one GPU

module purge
module load GCC/11.3.0  OpenMPI/4.1.4 AlphaFold/2.3.2-CUDA-11.8.0
module load AlphaPickle/1.4.1

################################### VARIABLES ##################################
# TODO Edit these variables as needed:

########## INPUTS ##########
protein_fasta='/scratch/data/bio/alphafold/example_data/1L2Y.fasta'

######## PARAMETERS ########
ALPHAFOLD_DATA_DIR='/scratch/data/bio/alphafold/2.3.2'  # 3TB data already downloaded here
max_template_date='2024-1-1'
model_preset='monomer_ptm'          # monomer, monomer_casp14, monomer_ptm, multimer
db_preset='reduced_dbs'             # full_dbs, reduced_dbs

########## OUTPUTS #########
protein_basename=$(basename ${protein_fasta%.*})
af_output_dir="out_${protein_basename}_${model_preset}_${db_preset}"
pickle_output_dir=${af_output_dir}/${protein_basename}

################################### COMMANDS ###################################

jobstats &

run_alphafold.py  \
  --data_dir=$ALPHAFOLD_DATA_DIR  --use_gpu_relax \
  --uniref90_database_path=$ALPHAFOLD_DATA_DIR/uniref90/uniref90.fasta  \
  --mgnify_database_path=$ALPHAFOLD_DATA_DIR/mgnify/mgy_clusters_2022_05.fa  \
  --small_bfd_database_path=$ALPHAFOLD_DATA_DIR/small_bfd/bfd-first_non_consensus_sequences.fasta \
  --pdb70_database_path=$ALPHAFOLD_DATA_DIR/pdb70/pdb70  \
  --template_mmcif_dir=$ALPHAFOLD_DATA_DIR/pdb_mmcif/mmcif_files  \
  --obsolete_pdbs_path=$ALPHAFOLD_DATA_DIR/pdb_mmcif/obsolete.dat \
  --model_preset=$model_preset \
  --max_template_date=$max_template_date \
  --db_preset=$db_preset \
  --output_dir=$af_output_dir \
  --fasta_paths=$protein_fasta

# graph pLDDT and PAE .pkl files
run_AlphaPickle.py -od $pickle_output_dir

jobstats

################################################################################
<<CITATIONS
    - Acknowledge TAMU HPRC: https://hprc.tamu.edu/research/citations.html

    - AlphaFold:
        Jumper, John et al. "Highly accurate protein structure prediction with AlphaFold". Nature 596. 7873(2021): 583–589.

        Tunyasuvunakool, Kathryn et al. "Highly accurate protein structure prediction for the human proteome". Nature 596. 7873(2021): 590–596.

    - AlphaFold-multimer:
        Evans, R et al. Protein complex prediction with AlphaFold-Multimer, doi.org/10.1101/2021.10.04.463034

    - AlphaPickle
        Arnold, M. J. (2021) AlphaPickle, doi.org/10.5281/zenodo.5708709
CITATIONS
