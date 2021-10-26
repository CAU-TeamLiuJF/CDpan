#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-03-15

package CDpan::Module::Align;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec::Functions qw /:ALL/;
use File::Path qw / rmtree /;
use File::Copy qw / copy move /;

use CDpan::Print qw / :PRINT /;

sub Align {
    (my $par, my $idv_name) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'),'align', $idv_name);
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $output_file_prefix = catfile($output_dir, $idv_name);

    my $input_file_prefix = catfile($par->val('CDPAN', 'input_dir'), $idv_name, $idv_name);
    if ($main::modules{ "align" }){
        unless ( -e "${input_file_prefix}_clean_1.fq.gz"){
            PrintErrorMessage("The input file ${input_file_prefix}_clean_1.fq.gz does not exist, whether the input direction is the output direction of Module filter");
        }
        unless ( -e "${input_file_prefix}_clean_2.fq.gz"){
            PrintErrorMessage("The input file ${input_file_prefix}_clean_2.fq.gz does not exist, whether the input direction is the output direction of Module filter");
        }
    }

    my $thread  = $par->val('CDPAN', 'thread');
    my $ref     = $par->val('ALIGN', 'ref_index');
    my $library = $par->val('ALIGN', 'library');

    # Read the software path
    my $bwa = $par->val('TOOLS', 'bwa');

    my $cmd_bwa = "$bwa mem -t $thread -M " .
                  "-R \"\@RG\\tID:${idv_name}\\tLB:${idv_name}\\tPL:$library\\tSM:${idv_name}\" " .
                  "$ref " .
                  "${input_file_prefix}_clean_1.fq.gz " .
                  "${input_file_prefix}_clean_2.fq.gz " .
                  "> ${output_file_prefix}.sam " .
                  "2> ${output_file_prefix}.sam.log";
    # print "Start use cmd: $cmd_bwa\n";
    PrintProcessMessage('aligning to the reference genome to %%', "${output_file_prefix}.sam");
    system $cmd_bwa
        and PrintErrorMessage("Command $cmd_bwa failed to run normally: $?");

    # Read the software path
    my $gatk = $par->val('TOOLS', 'gatk');

    #reorder sam
    my $cmd_reorder = "$gatk --java-options \"-Xmx64G\" ReorderSam " .
                      "--TMP_DIR $output_dir " .
                      "-I ${output_file_prefix}.sam " .
                      "-O ${output_file_prefix}.reorder.sam " .
                      "-R $ref " .
                      "-SD $ref.dict " .
                      ">/dev/null 2> ${output_file_prefix}.reorder.sam.log";
    # print "Start use cmd: $cmd_reorder\n";
    PrintProcessMessage('reorder sam to %%', "${output_file_prefix}.reorder.sam");
    system $cmd_reorder
        and PrintErrorMessage("Command $cmd_reorder failed to run normally: $?");

    # Read the software path
    my $samtools = $par->val('TOOLS', 'samtools');

    #sam to bam
    my $cmd_sam2bam = "$samtools view -@ $thread -b  " .
                      "-S ${output_file_prefix}.reorder.sam " .
                      "-o ${output_file_prefix}.reorder.bam " .
                      ">/dev/null 2>/dev/null";
    # print "Start use cmd: $cmd_sam2bam\n";
    PrintProcessMessage('sam to bam: %%', "${output_file_prefix}.reorder.bam");
    system $cmd_sam2bam
        and PrintErrorMessage("Command $cmd_sam2bam failed to run normally: $?");
    unlink "${output_file_prefix}.reorder.sam";

    #sort bam
    my $cmd_sort = "$gatk --java-options \"-Xmx64G\" SortSam " .
                   "--TMP_DIR $output_dir " .
                   "-I ${output_file_prefix}.reorder.bam " .
                   "-O ${output_file_prefix}.sort.bam " .
                   "--SORT_ORDER coordinate " .
                   ">/dev/null 2> ${output_file_prefix}.sort.bam.log";
    # print "Start use cmd: $cmd_sort\n";
    PrintProcessMessage('sort bam to %%', "${output_file_prefix}.sort.bam");
    system $cmd_sort
        and PrintErrorMessage("Command $cmd_sort failed to run normally: $?");

    if ( $par->val('CDPAN', 'output_level') == 1 ) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "${output_file_prefix}.sam" and
                $_ ne "${output_file_prefix}.reorder.sam" and
                $_ ne "${output_file_prefix}.reorder.bam" and
                $_ ne "${output_file_prefix}.sort.bam"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }
    elsif ( $par->val('CDPAN', 'output_level') == 0 ) {
        foreach (File::Slurp::read_dir($output_dir, prefix => 1)){
            if ( $_ ne "${output_file_prefix}.sort.bam"){
                unlink $_ or PrintErrorMessage("Cannot delete file: $_: $!");
            }
        }
    }

    return 1;
}

sub AlignIndex {
    (my $par) = @_;

    my $output_dir = catdir($par->val('CDPAN', 'work_dir'), 'ref_index');
    mkdir $output_dir or PrintErrorMessage("Cannot create direction $output_dir: $!");

    my $ref = $par->val('DATA', 'ref');
    (undef, undef, my $ref_name)= splitpath($ref);
    my $new_ref = catfile($output_dir, $ref_name);
    copy $ref, $new_ref
        or PrintErrorMessage("Cannot copy file $ref to $new_ref: $!");;
    $par->newval('ALIGN', 'ref_index', $new_ref);

    my $bwa = $par->val('TOOLS', 'bwa');

    my $cmd_bwa_index = "$bwa index $new_ref 2> /dev/null";
    # print "Start use cmd: $cmd_bwa_index\n";
    PrintProcessMessage('build index for %%',$new_ref);
    system $cmd_bwa_index
        and PrintErrorMessage("Error: Command $cmd_bwa_index failed to run normally: $?");

    my $gatk = $par->val('TOOLS', 'gatk');
    my $cmd_gatk_dict = "$gatk --java-options \"-Xmx64G\" CreateSequenceDictionary " .
                        "--TMP_DIR $output_dir " .
                        "-R $new_ref " .
                        "-O $new_ref.dict " .
                        ">/dev/null 2> /dev/null";
    # print "Start use cmd: $cmd_gatk_dict\n";
    PrintProcessMessage('build dictionary for %%', $new_ref);
    system $cmd_gatk_dict
        and PrintErrorMessage("Command $cmd_gatk_dict failed to run normally: $?");

    return 1;
}

sub AlignRemoveIndex {
    (my $par) = @_;

    my $index_dir = catdir($par->val('CDPAN', 'work_dir'), 'ref_index');
    if ( $par->val('CDPAN', 'output_level') < 2 ) {
        rmtree $index_dir or PrintErrorMessage("Cannot delete direction $index_dir: $!");
    }
    elsif ($main::modules{ "align" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'ref_index');
        move $index_dir, $output_dir or PrintErrorMessage("Couln't move $index_dir to $output_dir: $!");
    }elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }) {
        $par->newval('RESULT', 'ref_index', $index_dir);
    }

    return 1;
}

1;

__END__
