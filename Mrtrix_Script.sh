#!/bin/sh
#file format
#      After/
#          sub001/ sub002/ sub003..
#              dwi + T1
######################################
#          DICM to BIDS              #
######################################
begin_time=`date`

path=`pwd`
subs=`ls ./rawdata | grep sub*`

mkdir BIDS
mkdir output

for sub in $subs
do
docker run --rm -it -v $path:/base nipy/heudiconv:latest -d /base/rawdata/{subject}/*/*/*.IMA -o /base/BIDS -f /base/heuristic.py -s $sub -c dcm2niix -b --overwrite
done

sudo chmod -R a=rwx $path/BIDS
sudo chmod -R a=rwx $path/output

######################################
#    Data Pre-process via mrtrix3    #
######################################
####  Step 1 : Preprocess

for_each -nthreads 8 BIDS/sub* : mrconvert IN/dwi/*.nii.gz IN/PRE_dwi.mif -fslgrad IN/dwi/*.bvec IN/dwi/*.bval

for_each -nthreads 8 BIDS/sub* : dwidenoise IN/PRE_dwi.mif IN/PRE_dwi_den.mif -noise IN/noise.mif

for_each -nthreads 8 BIDS/sub* : mrdegibbs IN/PRE_dwi_den.mif IN/PRE_dwi_den_unr.mif

for_each -nthreads 8 BIDS/sub* : dwifslpreproc IN/PRE_dwi_den_unr.mif IN/PRE_dwi_den_unr_preproc.mif -pe_dir AP -rpe_none -eddy_options " --slm=linear --data_is_shelled"

for_each -nthreads 8 BIDS/sub* : dwibiascorrect ants IN/PRE_dwi_den_unr_preproc.mif IN/PRE_dwi_den_unr_preproc_unbiased.mif -bias IN/bias.mif

for_each -nthreads 8 BIDS/sub* : dwi2mask IN/PRE_dwi_den_unr_preproc_unbiased.mif IN/mask.mif

#### Step 2 : sigle shell - FOD
for_each -nthreads 8 BIDS/sub* : dwi2response tournier IN/PRE_dwi_den_unr_preproc_unbiased.mif IN/wm_csd.txt

for_each -nthreads 8 BIDS/sub* : dwi2fod csd IN/PRE_dwi_den_unr_preproc_unbiased.mif IN/wm_csd.txt IN/PRE_wm_csdfod.mif

#### Step 3 : Normalization
for_each -nthreads 8 BIDS/sub* : mtnormalise IN/PRE_wm_csdfod.mif IN/PRE_wmfod_norm.mif -mask IN/mask.mif

#### Step 4 : 5ttgen
for_each -nthreads 8 BIDS/sub* : mrconvert IN/anat/*.nii.gz IN/PRE_T1.mif
for_each -nthreads 8 BIDS/sub* : 5ttgen fsl IN/PRE_T1.mif IN/PRE_5tt_nocoreg.mif

#### Step 5 : registry
for_each -nthreads 8 BIDS/sub* : dwiextract -bzero IN/PRE_dwi_den_unr_preproc_unbiased.mif - \| mrmath - mean -axis 3 IN/mean_b0.mif
for_each -nthreads 8 BIDS/sub* : mrconvert IN/mean_b0.mif IN/mean_b0.nii.gz
for_each -nthreads 8 BIDS/sub* : mrconvert IN/PRE_5tt_nocoreg.mif IN/PRE_5tt_nocoreg.nii.gz
for_each -nthreads 8 BIDS/sub* : fslroi IN/PRE_5tt_nocoreg.nii.gz IN/PRE_5tt_vol0.nii.gz 0 1
for_each -nthreads 8 BIDS/sub* : flirt -in IN/mean_b0.nii.gz -ref IN/PRE_5tt_vol0.nii.gz -interp nearestneighbour -dof 6 -omat IN/diff2struct_fsl.mat
for_each -nthreads 8 BIDS/sub* : transformconvert IN/diff2struct_fsl.mat IN/mean_b0.nii.gz IN/PRE_5tt_nocoreg.nii.gz flirt_import IN/diff2struct_mrtrix.txt
for_each -nthreads 8 BIDS/sub* : mrtransform IN/PRE_5tt_nocoreg.mif -linear IN/diff2struct_mrtrix.txt -inverse IN/PRE_5tt_coreg.mif
for_each -nthreads 8 BIDS/sub* : 5tt2gmwmi IN/PRE_5tt_coreg.mif IN/gmwmSeed_coreg.mif

#### Step 6 : ACT
for_each -nthreads 8 BIDS/sub* : tckgen -act IN/PRE_5tt_coreg.mif -backtrack -seed_gmwmi IN/gmwmSeed_coreg.mif -maxlength 250 -cutoff 0.06 -select 10000000 IN/PRE_wmfod_norm.mif IN/PRE_tracks_10M.tck

#### Step 7 : SIFT2
for_each -nthreads 8 BIDS/sub* : tcksift2 -act IN/PRE_5tt_coreg.mif -out_mu IN/sift_mu.txt -out_coeffs IN/sift_coeffs.txt IN/PRE_tracks_10M.tck IN/PRE_wmfod_norm.mif IN/PRE_sift_1M.txt

#### Step 8 : recon-alli
for_each -nthreads 8 BIDS/sub* : recon-all -i IN/anat/*.nii.gz -s PRE -sd IN/ -all

#### Step 9 :segment
## self T1w space for IN/PRE/mri/aparc.a2009s+aseg.mgz
for_each -nthreads 8 BIDS/sub* : labelconvert IN/PRE/mri/aparc.a2009s+aseg.mgz $FREESURFER_HOME/FreeSurferColorLUT.txt /usr/local/mrtrix3/share/mrtrix3/labelconvert/fs_a2009s.txt IN/PRE_parcels_2009.mif

#### Step 10 : connectome
for_each -nthreads 8 BIDS/sub* : tck2connectome -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in IN/PRE_sift_1M.txt IN/PRE_tracks_10M.tck IN/PRE_parcels_2009.mif IN/PRE_parcels_2009.csv -out_assignment IN/assignments_PRE_parcels_2009.csv
## self connectome
for_each -nthreads 8 BIDS/sub* : cp IN/PRE_parcels_2009.csv output/

end_time=`date`

echo Congratulation!!!!!!!!!! Script runs from $begin_time to $end_time



