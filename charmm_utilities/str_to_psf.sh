#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    cat <<EOF
Automatic generation of PSF/PDB from MOL2/STR CHARMM inputs. 

Usage: $0 <input.str>

Where input.str is the output of the ParamChem website. Requires 
psfgen included in NAMD CVS >= 2014-06-17. Requires split_stream.pl
(https://github.com/tonigi/vmd_utilities).

EOF

    exit
fi

split_stream_pl=$HOME/compile/vmd_utilities/charmm_utilities/split_stream.pl
psfgen=psfgen

bn=`basename $1 .str`

echo "Generating mol2->pdb with openbabel"
obabel  $bn.mol2 -O$bn.pdb


res=`awk '/^RESI / {print $2}' $bn.str`
echo "Detected residue name $res"


echo "Splitting stream"
perl -w $split_stream $bn.str


echo "Generating PSF"
$psfgen <<EOF

topology top_$bn.rtf
topology top_all36_cgenff.rtf
pdbalias residue non $res

resetpsf

segment L1 { pdb $bn.pdb }
coordpdb $bn.pdb L1

# regenerate angles dihedrals

writepdb $bn-psf.pdb
writepsf $bn-psf.psf

EOF

