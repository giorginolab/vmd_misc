#!/usr/bin/perl -w

# TODO
#   exponential mean
#   merge gradients
#   a general matrix operation thing


use strict;
use Getopt::Long;
use Pod::Usage;

our $kT=0;
my $help=0;
my $bias=1.0;

GetOptions(
    'exponential=f'=>\$kT,
    'biasfactor=f'=>\$bias,
    'help|?' => \$help) or pod2usage(2);

if($help) {
    pod2usage(-verbose=>2);
    exit(0);
}

if(scalar @ARGV==0) {
    pod2usage(1);
    exit(0);
}



my $fn;
my $sum_grid='';

our $nfiles=scalar @ARGV;

# factor to convert bias into free energy
our $unbias;
if($bias != 1.0) {
    $unbias=$bias/($bias-1.0);
} else {
    $unbias=1.0;
}


for $fn (@ARGV) {
    my $cur_grid=readGrid($fn);
    if($kT!=0.0) {		# inversion
	$cur_grid=scalarTimesGrid($unbias,$cur_grid); # convert from bias to dG
	$cur_grid=arity1Grid(\&exp_XonkT,$cur_grid);
	    # probably this should be normalized to sum 1
	$cur_grid=normalizeGrid($cur_grid);
    }
    if($sum_grid) {
	$sum_grid=arity2Grid(\&add,$sum_grid,$cur_grid);
    } else {
	$sum_grid=$cur_grid;	# first file
    }
}

# Divide by number of files (average)
# Irrelevant if exp averaging (adds a constant)
$sum_grid=scalarTimesGrid(1.0/$nfiles,$sum_grid);

#   undo inversion & convert dG -> bias 
if($kT != 0.0) {		
    $sum_grid=arity1Grid(\&logX_kT,$sum_grid);
    $sum_grid=scalarTimesGrid(1.0/$unbias,$sum_grid);
}


writeGrid("/dev/stdout",$sum_grid);



sub exp_XonkT {
    my $dg=shift;
    return exp(-$dg/$kT);
}

sub logX_kT {
    my $p=shift;
    return -$kT*log($p);
}

sub scalarTimesGrid {
    our $c=shift;
    my $a=shift;
    return arity1Grid(sub { return $c*shift; },$a);
}




# apply a 1-ary function to two grids. Pass funcion by ref. Returns
# the result (a grid)
sub arity1Grid {
    my $fref=shift;		# function reference
    my $a=shift;		# arg 1

    my $res={};
    $res->{header}=$a->{header};
    $res->{cv}=$a->{cv};
    $res->{filename}="previous";

    for (my $i=0; $i<scalar @{$a->{cv}}; $i++) {
	$res->{bias}->[$i] = $fref->($a->{bias}->[$i]);
    }
    return $res;
}


# make the grid sum 1
sub normalizeGrid {
    my $a=shift;		# arg 1
    my $res={};
    $res->{header}=$a->{header};
    $res->{cv}=$a->{cv};
    $res->{filename}="previous";
    my $sum=0.0;
    for (my $i=0; $i<scalar @{$a->{cv}}; $i++) {
	$sum+=$a->{bias}->[$i];
    }
    for (my $i=0; $i<scalar @{$a->{cv}}; $i++) {
	$res->{bias}->[$i] = $a->{bias}->[$i] / $sum;
    }
    return $res;
}



sub add {
    my ($a,$b)=@_; 
    return $a+$b;  
}

# apply a 2-ary function to two grids. Pass funcion by ref. Returns
# the result (a grid)
sub arity2Grid {
    my $fref=shift;		# function reference
    my $a=shift;		# arg 1
    my $b=shift;		# arg 2

    my $res={};
    if(! equalHeaders($a,$b)) {
	die "Headers of $a->{filename} and $b->{filename} are different.";
    }
    $res->{header}=$a->{header};
    $res->{cv}=$a->{cv};
    $res->{filename}="previous";

    for (my $i=0; $i<scalar @{$a->{cv}}; $i++) {
	$res->{bias}->[$i] = $fref->($a->{bias}->[$i],$b->{bias}->[$i]);
    }
    return $res;
}






sub writeGrid {
    my $fn=shift;
    my $a=shift;
    my $l;
    open G,">$fn" or die "Can't write $fn: $!";
    for $l (@{$a->{header}}) {
	print G "$l\n";
    }
    for(my $i=0; $i<scalar @{$a->{cv}}; $i++) {
	my $cv=$a->{cv}->[$i];
	my $bias=$a->{bias}->[$i];
	print G "$cv $bias\n";
    }
    close G;
}


sub readGrid {
    my $f=shift;
    print STDERR "Reading grid from file $f\n";
    open F,"<$f" or die "Error opening $f: $!";
    my $nvar=0;			# CVs

    my $nh=0;			# no of header lines
    my @h;			# header

    my $ng=0;			# no of grid lines
    my @x;			# CV data
    my @b;			# bias data
    my @force;			# force
    while(my $l=<F>) {
	$l=~s/[\r\n]+$//;	# Win-friendly chomp
	$l=~s/FORCE 1/FORCE 0/;	# Discarding them
	my @fields=split(' ',$l);
	# chomp $l;		
	if($l=~/NVAR ([0-9]+)/) {
	    $nvar=$1;
	}
	if($l=~/^#/) {
#	    print "Found header $l\n";
	    $h[$nh]=$l;
	    $nh++;
	} elsif(scalar @fields>0) {
	    die "Parse error" if($nvar==0);
#	    print "Found body $l\n";
	    $x[$ng]=catN($nvar,@fields); # store CVs
	    $b[$ng]=$fields[$nvar];	 # store bias
	    # store force TODO
	    $ng++;
	} else {
	    # empty lines can be skipped, luckily
#	    print "Found empty line $l\n";
	}
    }
    close F;
    my $r={ header=>\@h,
	    cv=>\@x,
	    bias=>\@b,
            filename=>$f};
    return $r;
}


# concatenate the first N elements of the given array, return as
# string
sub catN {
    my $n=shift;
    my @f=@_;
    my $r="";

    for(my $i=0; $i<$n; $i++) {
	$r=$r.$f[$i]." ";
    }
    return $r;
}

# TODO
sub equalHeaders {
    return 1;
}


__END__

=head1 NAME

merge_grids - Sum or exponential sum of PLUMED grids

=head1 SYNOPSIS

merge_grids [options] [file ...]

Options:
  -exponential=FLOAT  Exponential averaging
  -biasfactor=FLOAT   Handle well-tempered grids
  -help               This help message

=head1 OPTIONS

=over 8

=item B<-exponential=FLOAT>

Use exponential (populations) averaging, rather than simply adding
free energies. Temperature (kT) must be given in units of the code. If
unset, normal averaging of free energies is used. If set, the 
resulting free energy will be

         -kT * log( mean( exp(-dG/kT) ) )

=item B<-biasfactor=FLOAT>

Undo the well-tempered biasing (required for well-tempered
simulations!).

=back

=head1 DESCRIPTION

The B<merge_grids> script combines grid files output by PLUMED with
the WRITE_GRID directive.

=cut
