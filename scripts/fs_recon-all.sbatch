#!/bin/bash
#SBATCH --partition=cpu_shared
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G
#SBATCH --time=4:00:00
#SBATCH --output=/users/kltoomer/datasets/hcp_retinotopy/code/logs/recon-all_%j.out
#SBATCH --error=/users/kltoomer/datasets/hcp_retinotopy/code/logs/recon-all_%j.err

# Define paths
SUBJECT_ID="sub-01"  # Change this
INPUT_DIR="/users/kltoomer/datasets/hcp_retinotopy/sourcedata/sub-01/anat/"  # Your T1w image location
OUTPUT_DIR="/users/kltoomer/datasets/hcp_retinotopy/derivatives/freesurfer_neurodesk/"  # Where you want results
SINGULARITY_CONTAINER="/users/kltoomer//bric/containers/apptainer/freesurfer_8.1.0_neurodesk.sif"

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

echo "Starting recon-all for ${SUBJECT_ID}"
echo "Using ${SLURM_CPUS_PER_TASK} CPUs"
echo "Job ID: ${SLURM_JOB_ID}"

# Run recon-all with Singularity
# (-B ${INPUT_DIR}:/input:ro) Input from host is read-only
# (-B ${OUTPUT_DIR}:/output) Host output is bound to /output & SUBJECTS_DIR is set to avoid 
# conflicts with freesurfer/subjects/... 

singularity run \
    -B ${INPUT_DIR}:/input:ro \
    -B ${OUTPUT_DIR}:/output \
    ${SINGULARITY_CONTAINER} \
    recon-all \
    -s ${SUBJECT_ID} \
    -i /input/${SUBJECT_ID}_acq-MPR1_T1w.nii.gz \
    -sd /output \
    -all \
    -openmp ${SLURM_CPUS_PER_TASK}
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "Success! Subject directory: ${SUBJECTS_DIR}/${SUBJECT_ID}"
else
    echo "recon-all failed with exit code ${EXIT_CODE}"
    exit ${EXIT_CODE}
fi

echo "Job completed at $(date)"