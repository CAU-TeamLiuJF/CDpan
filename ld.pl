#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

my $file = shift @ARGV;

open my $INPUT, "<", "${file}.ld" or die "Can't open plink.ld: $!";
open my $OUTPUT, ">>", "ld.${file}.results" or die "Can't open ld.results: $!";

<$INPUT>;

my $chr = undef;
my $R2 = undef;
my $chr_tmp = undef;
my $R2_tmp = undef;

my $line = undef;

while (<$INPUT>) {
    next if (m/DPS\S+ +\S+ $/);

    ($chr_tmp, $R2_tmp) = m/^ +\S+  +\S+ +\S+ +(\S+) +\S+ +\S+ +(\S+) $/;

    if ($R2_tmp eq '1') {
        if ($chr){
            if ( $chr ne $chr_tmp ){
                close $INPUT;
                close $OUTPUT;
                exit(-1);
            }
        }else{
            $chr = $chr_tmp;
        }
        $R2 = $R2_tmp;
        $line = $_;
    }else{
        next if ($R2 and $R2 > $R2_tmp);

        $R2 = $R2_tmp;
        $line = $_;
    }
}

print $OUTPUT $line if ($line);

close $INPUT;
close $OUTPUT;
exit(0);
