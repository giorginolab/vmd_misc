#!/bin/bash

# Obsoleted by plumed GUI

from=$1
to=$2

for i in `seq $from $to`; do
    im=$((i-1))
    ip=$((i+1))
    cat <<EOF
TORSION LIST [name C and resid $im] [name N and resid $i] [name CA and resid $i] [name C and resid $i]
TORSION LIST [name N and resid $i] [name CA and resid $i] [name C and resid $i] [name N and resid $ip]
EOF

done
