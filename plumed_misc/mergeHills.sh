#!/bin/bash

sum_hills=/shared/lab/software/metadynamics/PLUMED-1.2.0/utilities/sum_hills/sum_hills

if [ $# -eq 0 ]; then
    cat <<EOF
Merge all .hills files in current directory. Please supply
arguments to the sum_hills utility. IMPORTANT: fix grid boundaries
with option -fix.
EOF
    exit
fi

od=`pwd`
namelist=`ls -1 | fgrep .trunc |cut -f1 -d- |sort -n|uniq`

if [ -n $namelist ]; then 
    echo "No .hills file matched"
    exit
fi

tmpd=/tmp/mh.$USER.$$
mkdir $tmpd

i=0
for n in $namelist; do
    lasth=`ls -1 --sort=v $n-*.trunc | tail -1`
    echo $sum_hills  -file $lasth  $@
    $sum_hills  -file $lasth  $@
    mv fes.dat $tmpd/fes.$i
    i=$((i+1))
done

awk -v kbt=0.5969 '
{
  dg=$NF;			# dG
  $NF="";
  x=$0;				# all x1..xn
  xr[FNR] = x;
  sg[FNR] += dg;
  sp[FNR] += exp(-dg/kbt);
}
END {
  nf=ARGC-1;
  for (i=1;i<=FNR;i++) {
    if(xr[i]=="") {
      print "";
    } else {
      print xr[i] " " (-kbt*log(sp[i]/nf)) " " (sg[i]/nf) ;
    }
  }
}  
' $tmpd/fes.* > fes.all

echo "Created file fes.all. Temporary fes.xx left in $tmpd"
