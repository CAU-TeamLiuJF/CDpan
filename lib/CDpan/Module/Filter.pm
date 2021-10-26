#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-03-02

package CDpan::Module::Filter;

use strict;
use warnings;

use File::Spec::Functions qw /:ALL/;
use Config::IniFiles;
use File::Slurp;

use CDpan::Print qw / :PRINT /;

sub Filter {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'filter', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my @idv_file;
    foreach my $file (File::Slurp::read_dir( catdir($par->val('CDPAN', 'input_dir'), $idv_name ), prefix => 1)) {
        if ( $file =~ m/\S+_[12]\.fq\.gz$/ ){
            push @idv_file, $file;
        }else{
            PrintWarnMessage("Incorrectly formatted genotype data: $file, ignore it");
        }
    }
    PrintErrorMessage("The number of genome data in the direction @idv_file is abnormal (singular).") if ( @idv_file & 1);
    @idv_file = sort @idv_file;

    # my $name;
    my $count = 1;
    foreach my $file (@idv_file) {
        if ( $count & 1 ) {
            # PrintErrorMessage("Two-paired data does not match: $file") unless ( ($name) = $file =~ m/\S+\/(\S+?)1?\S*_1\.fq\.gz$/ );
            PrintErrorMessage("Two-paired data does not match: $file") unless ( $file =~ m/\S+_1\.fq\.gz$/ );
        } else {
            # PrintErrorMessage("Two-paired data does not match: $file") unless ( $file =~ m/\S+\/${name}2?\S*_2\.fq\.gz$/ );
            PrintErrorMessage("Two-paired data does not match: $file") unless ( $file =~ m/\S+_2\.fq\.gz$/ );
        }

       $count += 1;
    }

    my $idv_file_amount = @idv_file;

    # The default value is set when the parameter is imported, and there is no need to handle it here
    my $quality     = $par->val('FILTER', 'quality');
    my $length      = $par->val('FILTER', 'length');
    my $error_rate  = $par->val('FILTER', 'error-rate');
    my $thread      = $par->val('CDPAN',  'thread');

    # Read the software path
    my $trim_galore = $par->val('TOOLS', 'trim_galore');
    my $cutadapt    = $par->val('TOOLS', 'cutadapt');
    my $fastqc      = $par->val('TOOLS', 'fastqc');

    while (@idv_file) {
        my $paired1 = shift @idv_file;
        my $paired2 = shift @idv_file;
        my $cmd_trim_galore = "$trim_galore " .
                              "--quality $quality " .
                              "--phred33 " .
                              "--stringency 3 " .
                              "--length $length " .
                              "-e $error_rate " .
                              "--paired $paired1 $paired2 " .
                              "--gzip " .
                              "--output_dir $output_dir " .
                              "-j $thread " .
                              "2> /dev/null";
        # print "Start use cmd: $cmd_trim_galore\n";
        PrintProcessMessage('quality control for %% %%',$paired1,$paired2);
        system $cmd_trim_galore
            and PrintErrorMessage("Command $cmd_trim_galore failed to run normally: $?");
    }

    # merge data
    my @result_files_all = sort ( File::Slurp::read_dir($output_dir, prefix => 1) );
    my @result_files_1;
    my @result_files_2;
    foreach my $file (@result_files_all) {
        if ( $file =~ m/\Q_1_val_1.fq.gz\E$/ ) {
            push @result_files_1, $file;
        }elsif ( $file =~ m/\Q_2_val_2.fq.gz\E$/ ) {
            push @result_files_2, $file;
        }
    }
    unless ( (@result_files_1 == @result_files_2) && ( @result_files_1 == ($idv_file_amount >> 1) ) ) {
        PrintErrorMessage("The number of result files of trim_galore is abnormal, trim_galore may not be running normally");
    }

    @result_files_1 = sort @result_files_1;
    @result_files_2 = sort @result_files_2;

    my $cmd_merge_data_1 = "cat @result_files_1 > ${output_file_prefix}_clean_1.fq.gz";
    # print "Start use cmd: $cmd_merge_data_1\n";
    PrintProcessMessage('merge %%=> %%', \@result_files_1, "${output_file_prefix}_clean_1.fq.gz");
    system $cmd_merge_data_1
        and PrintErrorMessage("Command $cmd_merge_data_1 failed to run normally: $?");

    my $cmd_merge_data_2 = "cat @result_files_2 > ${output_file_prefix}_clean_2.fq.gz";
    # print "Start use cmd: $cmd_merge_data_2\n";
    PrintProcessMessage('merge %%=> %%', \@result_files_2, "${output_file_prefix}_clean_2.fq.gz");
    system $cmd_merge_data_2
        and PrintErrorMessage("Command $cmd_merge_data_2 failed to run normally: $?");

    if ( $par->val('CDPAN', 'output_level') < 2 ) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "${output_file_prefix}_clean_1.fq.gz" and
                $_ ne "${output_file_prefix}_clean_2.fq.gz"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }

    return 1;
}


1;

__END__
