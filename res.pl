#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

# my $file_cov = shift;
# my $file_merge = shift;
my $file_cov = 'compare_0.8.txt_Cov4x_output.csv';
my $file_merge = 'out.20.txt_output.csv';

# my $file_out = shift;
my $file_out = 'res_contigs.csv';

my $max_contig = 1000000;  # 1Mb

sub LengthOfContig {
    (my $contig_1_l, my $contig_1_r, my $contig_2_l, my $contig_2_r) = @_;
    if ($contig_1_r < $contig_2_l){
        return ($contig_2_l - $contig_1_r)
    }
    elsif ($contig_1_l > $contig_2_r){
        return ($contig_1_l - $contig_2_r)
    }
    else{
        return 0
    }
}

my %contigs_cov;
open my $INPUT, "<", $file_cov or die "Can't open $file_cov: $!\n";
while (<$INPUT>) {
    next unless my @lines = m/^([^,]+),([^,]+),([^,]+),([^,]+)\n$/;
    $contigs_cov{$lines[0]} = [ @lines ];
}
close $INPUT;

open $INPUT, "<", $file_merge or die "Can't open $file_merge: $!\n";
open my $OUTPUT, ">", $file_out or die "Can't open $file_out: $!\n";
printf $OUTPUT "Contig,LD higest,LD higest,LD higest,LD second,LD second,LD second,Blast Best,Blast Best,Blast Best,Blast Second,Blast Second,Blast Second,Blast Third,Blast Third,Blast Third,Merge,Merge,Merge,Cov4x,Cov4x,Cov4x,Res,Res,Res\n";
printf $OUTPUT "Contig,chromosome,Location,Vote,chromosome,Location,Vote,chromosome,Start,End,chromosome,Start,End,chromosome,Start,End,chromosome,Start,End,chromosome,Start,End,chromosome,Start,End\n";
while (<$INPUT>) {
    chomp;
    (my $contig_id,my $chr,my $start,my $stop) = m/^([^,]+),\S+,([^,]*),([^,]*),([^,]*)$/;
    if ($contigs_cov{$contig_id}) {
        (undef,my $chr_cov,my $start_cov,my $stop_cov) = @{ $contigs_cov{$contig_id} };
        if ($chr eq '') {
            printf $OUTPUT "$_,$chr_cov,$start_cov,$stop_cov,$chr_cov,$start_cov,$stop_cov\n";
        }else{
            if ($chr eq $chr_cov and LengthOfContig($start,$stop,$start_cov,$stop_cov) < $max_contig) {
                printf $OUTPUT "$_,$chr_cov,$start_cov,$stop_cov,$chr_cov,$start_cov,$stop_cov\n";
            }else{
                printf $OUTPUT "$_,,,,,,\n";
            }
        }
    }else{
        printf $OUTPUT "$_,,,,$chr,$start,$stop\n";
    }

}
close $INPUT;
close $OUTPUT;

# (my $contig_id,my $chr,my $start,my $stop)


# while (<$INPUT>) {
#     next unless (my $idv_info) = m/^(\S+) / ;
#     if ($idv{$idv_info}) {
#         if ($test{$idv_info}){
#             s/ \S+\n$/ -9\n/;
#         }
#         printf $OUTPUT $_;
#     }
# }
