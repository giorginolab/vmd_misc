BEGIN {
    print "# NAMD extended system trajectory file";
    print "#$LABELS step a_x a_y a_z b_x b_y b_z c_x c_y c_z o_x o_y o_z s_x s_y s_z s_u s_v s_w";
    i=0;
}

NF==9 && $2!="X" {
    print i++, $1*10, $4*10, $5*10,  $6*10, $2*10, $7*10,  $8*10, $9*10, $3*10,  0.00, 0.00, 0.00;
}
