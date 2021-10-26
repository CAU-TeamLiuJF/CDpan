#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-03-25

package CDpan::Module::Extract;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec::Functions qw /:ALL/;

use CDpan::Print qw / :PRINT /;

sub Extract {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'extract', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "extract" }){
        unless ( -e "${input_file_prefix}.sort.bam"){
            PrintErrorMessage("The input file ${input_file_prefix}.sort.bam does not exist, whether the input direction is the output direction of Module align");
        }
    }

    my $thread  = $par->val('CDPAN', 'thread');

    # Read the software path
    my $samtools = $par->val('TOOLS', 'samtools');

    my $cmd_fastq1 = "$samtools fastq -\@ $thread " .
                     "-f 12 ${input_file_prefix}.sort.bam " .
                     "-1 ${output_file_prefix}.mateUnmapped_R1.fq " .
                     "-2 ${output_file_prefix}.mateUnmapped_R2.fq " .
                     "2> /dev/null";
    # print "Start use cmd: \'$cmd_fastq1\'.\n";
    PrintProcessMessage('extract to %% %%', "${output_file_prefix}.mateUnmapped_R1.fq", "${output_file_prefix}.mateUnmapped_R2.fq");
    system $cmd_fastq1
        and PrintErrorMessage("Command \'$cmd_fastq1\' failed to run normally: $?");

    my $cmd_fastq2 = "$samtools fastq -\@ $thread " .
                     "-f 68 -F 8 ${input_file_prefix}.sort.bam " .
                     "> ${output_file_prefix}.R1_mateMapped.fq " .
                     "2> /dev/null";
    # print "Start use cmd: \'$cmd_fastq2\'.\n";
    PrintProcessMessage('extract to %%', "${output_file_prefix}.R1_mateMapped.fq");
    system $cmd_fastq2
        and PrintErrorMessage("Command \'$cmd_fastq2\' failed to run normally: $?");

    my $cmd_fastq3 = "$samtools fastq -\@ $thread " .
                     "-f 132 -F 8 ${input_file_prefix}.sort.bam " .
                     "> ${output_file_prefix}.R2_mateMapped.fq " .
                     "2> /dev/null";
    # print "Start use cmd: \'$cmd_fastq3\'.\n";
    PrintProcessMessage('extract to %%', "${output_file_prefix}.R2_mateMapped.fq");
    system $cmd_fastq3
        and PrintErrorMessage("Command \'$cmd_fastq3\' failed to run normally: $?");

    my $cmd_view = "$samtools view -\@ $thread " .
                   "-f 8 -F 4 -b -h ${input_file_prefix}.sort.bam " .
                   "> ${output_file_prefix}.Sus_11_1_Links.bam ";
    # print "Start use cmd: \'$cmd_view\'.\n";
    PrintProcessMessage('extract to %%', "${output_file_prefix}.Sus_11_1_Links.bam");
    system $cmd_view
        and PrintErrorMessage("Command \'$cmd_view\' failed to run normally: $?");

    my $cmd_fastq4 = "$samtools fastq -\@ $thread " .
                     "-f 4 ${input_file_prefix}.sort.bam " .
                     "-1 ${output_file_prefix}.singleUnmapped_R1.fq " .
                     "-2 ${output_file_prefix}.singleUnmapped_R2.fq " .
                     "2> /dev/null";
    # print "Start use cmd: \'$cmd_fastq4\'.\n";
    PrintProcessMessage('extract to %% %%', "${output_file_prefix}.singleUnmapped_R1.fq", "${output_file_prefix}.singleUnmapped_R2.fq");
    system $cmd_fastq4
        and PrintErrorMessage("Command \'$cmd_fastq4\' failed to run normally: $?");


    if ( $par->val('CDPAN', 'output_level')  < 3) {
        ; # all of the output file is used
    }

    return 1;
}


1;

__END__
