#!/bin/sh
sif_dir="/users/kltoomer/bric/containers/apptainer/sif"
sif_name="freesurfer_8.1.0_neurodesk"

# Adapted from A.Praveen (2025)
TGT="$(basename $0)"
module purge
if [ $(hostname) = "gnode01" -o $(hostname) = "gnode02" ]
then
        exec singularity run -B /users,/scratch --nv "${sif_dir}/${sif_name}.sif" "$TGT" "$@"
else
        exec singularity run -B /users,/scratch "${sif_dir}/${sif_name}.sif" "$TGT" "$@"
fi