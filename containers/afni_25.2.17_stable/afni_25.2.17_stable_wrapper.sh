#!/bin/sh
TGT="$(basename $0)"
module purge
if [ $(hostname) = "gnode01" -o $(hostname) = "gnode02" ]
then
        exec singularity run -B /users,/scratch --nv /users/kltoomer/bric/containers/afni_25.2.17_stable/afni_25.2.17_stable.sif "$TGT" "$@"
else
        exec singularity run -B /users,/scratch /users/kltoomer/bric/containers/afni_25.2.17_stable/afni_25.2.17_stable.sif "$TGT" "$@"
fi