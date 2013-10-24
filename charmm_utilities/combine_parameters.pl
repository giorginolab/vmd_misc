#!/usr/bin/perl -w

my $DISCLAIMER=<<EOF;
This hack combines various sections of several CHARMM-style parameter
files.  The result MAY BE WRONG.  You should be doing this by hand.
This script only provides a draft.  POSITIVELY DO NOT TRUST the
resulting parameter file.  NBFIX, cutoffs, and many other parts
are corrupted, and syntax errors are introduced. Triple-check!

You should only rely on official software and your knowledge, not
this script, to merge parameter files. TG - version of 16-Oct-2013
EOF

# http://www.charmm.org/html/documentation/c35b1/parmfile.html
# http://www.charmm.org/html/documentation/c35b1/io.html#%20Read

# Toni G - DO NOT DISTRIBUTE
# Version of 16-Oct-2013


use Cwd 'abs_path';
use strict;
use File::Basename;

my $input_list="@ARGV";
my $input_date=localtime;
my $input_version='$Id: 16-Oct-2013 $';

my $head="";
my $atom="";
my $equi="";
my $bond="";
my $angl="";
my $dihe="";
my $imph="";
my $cmap="";
my $nbond="";
my $nbfix="";
my $hbond="";

my $r=\$head;


my $keep_atom_section=0;
my $cutnb_fix=0;		
my $cutnb_fix_flag=0;		


my ($basename,$dir,$suffix)=fileparse(abs_path($0));

if (scalar @ARGV==0) {
	help();
	exit;
}

while ($_ = $ARGV[0], /^-/) {
    shift;
    last if /^--$/;
    if (/^-h/) { 
	help();
	exit; 
    }
    if (/^-a/) {
	$keep_atom_section=1;
    }
    if (/^-f/) {
	$cutnb_fix=1;
    }
}

for(my $i=0; $i<scalar @ARGV; $i++) {
    my $fn=\$ARGV[$i];
    if($$fn =~ /toppar_(.+).str$/) {
	print STDERR "Invoking $dir/split_stream on $$fn\n";
	system("perl $dir/split_stream.pl $$fn");
	$$fn = "par_$1.prm";
    }
}



my $start=1;
while(my $l=<>) {
	if($start) {
		name($r);
		$start=0;
	}
	
	if($l=~/^ *cutnb/i && $cutnb_fix) {
	    $cutnb_fix_flag++;
	    if ($cutnb_fix_flag>1) {
		print STDERR "Removing cutnb line no. $cutnb_fix_flag: $l";
		$l="! $l";
	    } 
	}

 	if($l=~/^ATOM/i) { $r=\$atom; name($r);}
 	elsif($l=~/^EQUI/i) { $r=\$equi; name($r);}
 	elsif($l=~/^BOND/i) { $r=\$bond; name($r);}
 	elsif($l=~/^ANGL/i || $l=~/^THET/i ) { $r=\$angl; name($r);}
 	elsif($l=~/^DIHE/i || $l=~/^PHI/i) { $r=\$dihe; name($r);}
 	elsif($l=~/^IMPR/i || $l=~/^IMPH/i) { $r=\$imph; name($r);}
 	elsif($l=~/^NONB/i || $l=~/^NBON/i ) { $r=\$nbond; name($r);}
 	elsif($l=~/^CMAP/i) { $r=\$cmap; name($r); }
 	elsif($l=~/^NBFIX/i) { $r=\$nbfix; name($r); }
 	elsif($l=~/^HBOND/i) { $r=\$hbond; name($r);}
 	elsif($l=~/^END/i) { $r=\$head; name($r);}
	else {
 		$$r .= $l;
 	}
	print STDERR "Finished processing $ARGV\n" if eof;
}


$atom="ATOM\n".$atom;
$equi="EQUI\n".$equi;

if(!$keep_atom_section) {
	$atom=comment($atom);
	$equi=comment($equi);
}


print <<EOF;
* Combined parameter file generated from $input_list
* Date: $input_date
* Script version: $input_version
* THIS PARAMETER FILE MAY CONTAIN SERIOUS ERRORS
$head

$atom

$equi

BONDS
$bond

ANGLES
$angl

DIHEDRALS
$dihe

IMPROPER
$imph

NBOND
$nbond

CMAP
$cmap

NBFIX
$nbfix

HBOND
$hbond

END
EOF


print STDERR "Done.\n\n$DISCLAIMER";


sub name {
	my ($dest)=@_;
	$$dest .= "! (Following lines from $ARGV)\n";	
}

sub comment {
	my $in=shift;
	$in =~ s/^/! /gm;
	$in =<<EOF;
! The following flexible-parameters section was removed by combine-parameters.pl
$in
EOF
	return $in;
}

sub help {
	print <<EOF;

Usage: combine_parameters.pl [-a] [-f] [par_xxx.prm] [par_yyy.prm] ... > combined.inp

 -f  Comment out cutnb lines except the first (experimental)
 -a  Keep ATOMS section (useless)

$DISCLAIMER
EOF
}

