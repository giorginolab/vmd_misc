#!/bin/bash

# Combine well-known CHARMM parameter files into one

function ech () {
	echo -e "\n\n\n*********** $1 \n\n\n"
}

# All files contained in this archive from 
# http://mackerell.umaryland.edu/CHARMM_ff_params.html
# File: toppar_c36_aug12.tgz


c36=toppar_c36_aug12.tgz
ech "1. Getting $c36 from http://mackerell.umaryland.edu..."

if [ ! -f $c36 ]; then
	wget 'http://mackerell.umaryland.edu/download.php?filename=CHARMM_ff_params_files/toppar_c36_aug12.tgz' -O $c36
else
	echo "Already there"
fi

tar -zxvf $c36


# Split the water stream and fix leading asterisks
ech "2. Splitting water stream"
../split_stream.pl toppar/toppar_water_ions.str
sed -i 's/^\*/!/g' par_water_ions.prm;


# Combine
ech "3. Combining parameters"
../combine_parameters.pl -f \
	toppar/par_all36_prot.prm \
	toppar/par_all36_cgenff.prm \
	toppar/par_all36_lipid.prm \
	toppar/par_all36_na.prm \
	toppar/par_all35_ethers.prm \
	toppar/par_all36_carb.prm \
	par_water_ions.prm \
		> par_all36_prot22_na_lipid_carb_ethers_cgenff_water_ions.prm



# Charmm22* Parameters from
# http://home.uchicago.edu/~/kippjohnson/par_all22star_prot_revision-one.inp
# (which includes water and ions)
# 108b83d5b5e33e13bd9ecd0592c45c60  par_all22star_prot_revision-one.inp

ech "4. Getting Charmm22* revision one from home.uchicago.edu/~/kippjohnson"
wget -N http://home.uchicago.edu/~/kippjohnson/par_all22star_prot_revision-one.inp

ech "5. Merging parameters"
../combine_parameters.pl -f par_all22star_prot_revision-one.inp \
	toppar/par_all36_cgenff.prm \
	toppar/par_all36_lipid.prm \
	toppar/par_all36_na.prm \
	toppar/par_all35_ethers.prm \
	toppar/par_all36_carb.prm \
		> par_all36_prot22star_na_lipid_carb_ethers_cgenff_water_ions.prm


