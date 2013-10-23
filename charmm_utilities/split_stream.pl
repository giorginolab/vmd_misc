#!/usr/bin/perl -w
# http://www.charmm.org/html/documentation/c35b1/parmfile.html
# http://www.charmm.org/html/documentation/c35b1/io.html#%20Read

use strict;
use File::Basename;


my $rtf="";
my $prm="";
my $junk="";

my $r=\$junk;
my $warn_rtf=0;
my $warn_prm=0;

my($basename, $directories, $suffix) = fileparse($ARGV[0]);
$basename=~s/.str$//;
$basename=~s/^toppar_//;
my $ortf="top_$basename.rtf";
my $oprm="par_$basename.prm";


while(my $l=<>) {
 	if($l=~/^read rtf card/i) { 
 		$r=\$rtf;
 		if($$r) {
 			$$r.="! WARNING -- ANOTHER rtf SECTION FOUND\n";
 			$warn_rtf++;
 		}
 	}
 	elsif($l=~/^read param? card/i) { 
 		$r=\$prm; 
 		if($$r) {
 			$$r.="! WARNING -- ANOTHER para SECTION FOUND\n";
 			$warn_prm++;
 		}
 	}
 	elsif($l=~/^end/i) { $r=\$junk; }
 	else {
 		$$r .= $l;
 	}
}

if($warn_rtf || $warn_prm) {
	print STDERR "Warning - duplicate sections found. You need to revise the outputs marked with [*]\n";
}

my $w;
$w="*"x$warn_rtf;
print STDERR "Creating $ortf $w\n";
open R,">$ortf";
print R $rtf;
print R "END\n";
close R;

$w="*"x$warn_prm;
print STDERR "Creating $oprm $w\n";
open P,">$oprm";
print P $prm;
print P "END\n";
close P;



