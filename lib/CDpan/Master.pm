#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-10-09

package CDpan::Master;

use strict;
use warnings;

use File::Spec::Functions qw /:ALL/;
use File::Copy qw / copy move /;
use File::Path qw / rmtree /;
use Config::IniFiles;
use File::Slurp;

use CDpan::Print qw / :PRINT /;

use CDpan::Module::Filter;
use CDpan::Module::Align;
use CDpan::Module::Extract;
use CDpan::Module::Assembly;
use CDpan::Module::Mope;
use CDpan::Module::Vot;
use CDpan::Module::Soot;
use CDpan::Module::Merge;
use CDpan::Module::Location;

sub Filter {
    (my $par) = @_;

    PrintStartMessage("Start Module filter");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'filter');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Filter::Filter($par, $idv_name) or PrintErrorMessage("Module filter exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "filter" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'filter');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'filter', $output_dir);

        PrintMessage("Since module filter is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'filter', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module align\n");
    }

    PrintEndMessage("Finish Module filter");

    return 1;
};

sub Align {
    (my $par) = @_;

    PrintStartMessage("Start Module align");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'align');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    PrintMessage("Index\n");
    CDpan::Module::Align::AlignIndex($par) or PrintErrorMessage("Module align exited abnormally when build index");
    PrintMessage("\n");

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Align::Align($par, $idv_name) or PrintErrorMessage("Module align exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    CDpan::Module::Align::AlignRemoveIndex($par) or PrintErrorMessage("Module align exited abnormally when remove index");

    if ($main::modules{ "align" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'align');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'align', $output_dir);

        PrintMessage("Since module align is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'align', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module extract\n");
    }

    PrintEndMessage("Finish Module align");

    return 1;
};

sub Extract {
    (my $par) = @_;

    PrintStartMessage("Start Module extract");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'extract');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Extract::Extract($par, $idv_name) or PrintErrorMessage("Module extract exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "extract" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'extract');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'extract', $output_dir);

        PrintMessage("Since module extract is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'extract', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module assembly\n");
    }

    PrintEndMessage("Finish Module extract");

    return 1;
};

sub Assembly {
    (my $par) = @_;

    PrintStartMessage("Start Module assembly");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'assembly');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Assembly::Assembly($par, $idv_name) or PrintErrorMessage("Module assembly exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "assembly" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'assembly');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'assembly', $output_dir);

        PrintMessage("Since module assembly is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'assembly', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module mope\n");
    }

    PrintEndMessage("Finish Module assembly");

    return 1;
};

sub Mope {
    (my $par) = @_;

    PrintStartMessage("Start Module mope");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'mope');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Mope::Mope($par, $idv_name) or PrintErrorMessage("Module mope exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "mope" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'mope');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'mope', $output_dir);

        PrintMessage("Since module mope is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'mope', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module vot\n");
    }

    PrintEndMessage("Finish Module mope");

    return 1;
};


sub Vot {
    (my $par) = @_;

    PrintStartMessage("Start Module vot");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'vot');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Vot::Vot($par, $idv_name) or PrintErrorMessage("Module vot exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "vot" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'vot');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'vot', $output_dir);

        PrintMessage("Since module vot is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'vot', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module soot\n");
    }

    PrintEndMessage("Finish Module vot");

    return 1;
};

sub Soot {
    (my $par) = @_;

    PrintStartMessage("Start Module soot");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'soot');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Soot::Soot($par, $idv_name) or PrintErrorMessage("Module soot exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "soot" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'soot');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'soot', $output_dir);

        PrintMessage("Since module soot is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'soot', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module merge\n");
    }

    PrintEndMessage("Finish Module soot");

    return 1;
};

sub Merge {
    (my $par) = @_;

    PrintStartMessage("Start Module merge");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'merge');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Merge::Merge($par, $idv_name) or PrintErrorMessage("Module merge exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    if ($main::modules{ "merge" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'merge');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'merge', $output_dir);

        PrintMessage("Since module merge is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'merge', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("Since module $main::module is being used, continue to run module location\n");
    }

    PrintEndMessage("Finish Module merge");

    return 1;
};

sub Location {
    (my $par) = @_;

    PrintStartMessage("Start Module location");

    PrintMessage("Index\n");
    CDpan::Module::Location::PreLocation($par)
        or PrintErrorMessage("Module location exited abnormally when do PreLocation");
    PrintMessage("\n");

    my $work_dir = catdir($par->val('CDPAN', 'work_dir'), 'location');
    mkdir $work_dir or PrintErrorMessage("Cannot create work direction $work_dir: $!");

    my $extract_dir = $par->val('RESULT', 'extract') // $par->val('LOCATION', 'extract_dir');
    $par->setval('CDPAN', 'input_dir', $extract_dir);
    my @input_idvs = sort ( File::Slurp::read_dir( $par->val('CDPAN', 'input_dir')) );

    foreach my $idv_name (@input_idvs) {
        PrintMessage("Processing: $idv_name\n");
        CDpan::Module::Location::Location($par, $idv_name) or PrintErrorMessage("Module location exited abnormally for $idv_name");
        PrintMessage("\n");
    }

    CDpan::Module::Location::Compare($par)
         or PrintErrorMessage("Module location exited abnormally when do compare");

    CDpan::Module::Location::RemovePreLocation($par)
        or PrintErrorMessage("Module location exited abnormally when remove PreLocation");

    if ( $par->val('CDPAN', 'output_level') == 0 ) {
        foreach my $idv_name (@input_idvs) {
            my $idv_output_dir = catdir($par->val('CDPAN', 'work_dir'),'location', $idv_name);
            rmtree $idv_output_dir or PrintErrorMessage("Cannot delete direction $idv_output_dir: $!");
        }
    }

    if ($main::modules{ "location" }){
        my $output_dir = catdir($par->val('CDPAN', 'output_dir'), 'location');
        move $work_dir, $output_dir or PrintErrorMessage("Couln't move $work_dir to $output_dir: $!");
        $par->newval('RESULT', 'location', $output_dir);

        PrintMessage("ALL individuals' previous results were integrated into $output_dir.compare.txt\n");
        PrintMessage("Since module location is being used, program will end\n");
    }
    elsif ($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }){
        $par->newval('RESULT', 'location', $work_dir);
        $par->setval('CDPAN', 'input_dir', $work_dir);

        PrintMessage("ALL individuals' previous results were integrated into $main::output_prefix.location.txt\n");
        PrintMessage("Since module $main::module is being used, program will end\n");
    }



    PrintEndMessage("Finish Module location");

    return 1;
};

sub RunDiem {
    (my $par) = @_;

    PrintStartMessage("Start Module RUN-DIEM");
    PrintMessage("The following modules will be executed sequentially:\n");
    PrintMessage("    filter align extract assembly mope vot soot merge\n\n");

    Filter   ( $par ) unless ($main::no_quality_control);
    Align    ( $par );
    Extract  ( $par );
    Assembly ( $par );
    Mope     ( $par );
    Vot      ( $par );
    Soot     ( $par );
    Merge    ( $par );

    my $result_file = catfile($par->val('RESULT', 'merge'), 'merge.fasta');
    my $output_file = catfile($par->val('CDPAN', 'output_dir'), "$main::output_prefix.dispensable_genome.fasta");
    copy $result_file,$output_file
        or PrintErrorMessage("Cannot copy file $result_file to $output_file: $!");
    $par->newval('RESULT', 'dispensable_genome.fasta', $output_file);

    my @modules_by_rundiem = qw \ filter align extract assembly mope vot soot merge \;
    foreach my $module_by_rundiem ( @modules_by_rundiem) {
        my $result_dir = $par->val('RESULT', $module_by_rundiem);
        if ( $par->val('CDPAN', 'output_level') == 0) {
            $par->delval('RESULT', $module_by_rundiem);
        }
        else {
            my $output_dir = catdir($par->val('CDPAN', 'output_dir'), $module_by_rundiem);
            move $result_dir, $output_dir or PrintErrorMessage("Couln't move $result_dir to $output_dir: $!");
            $par->setval('RESULT', $module_by_rundiem, $output_dir);
        }
    }

    unless ( $par->val('CDPAN', 'output_level') == 0) {
        my $index_dir = $par->val('RESULT', 'ref_index');
        my $index_output_dir = catdir($par->val('CDPAN', 'output_dir'), 'ref_index');
        move $index_dir, $index_output_dir or PrintErrorMessage("Couln't move $index_dir to $index_output_dir: $!");
        $par->delval('RESULT', 'ref_index');
    }

    PrintStartMessage("All modules have been executed for Module RUN-DIEM");

    PrintEndMessage("Finish Module RUN-DIEM");

    return 1;
};

sub RunAll {
    (my $par) = @_;

    PrintStartMessage("Start Module RUN-ALL");
    PrintMessage("The following modules will be executed sequentially:\n");
    PrintMessage("    filter align extract assembly mope vot soot merge location\n\n");

    Filter   ( $par ) unless ($main::no_quality_control);
    Align    ( $par );
    Extract  ( $par );
    Assembly ( $par );
    Mope     ( $par );
    Vot      ( $par );
    Soot     ( $par );
    Merge    ( $par );
    Location ( $par );

    my $result_file = catfile($par->val('RESULT', 'merge'), 'merge.fasta');
    my $output_file = catfile($par->val('CDPAN', 'output_dir'), "$main::output_prefix.dispensable_genome.fasta");
    copy $result_file,$output_file
        or PrintErrorMessage("Cannot copy file $result_file to $output_file: $!");
    $par->newval('RESULT', 'dispensable_genome_fasta', $output_file);

    $result_file = catfile($par->val('RESULT', 'location'), 'compare.txt');
    $output_file = catfile($par->val('CDPAN', 'output_dir'), "$main::output_prefix.location.txt");
    copy $result_file,$output_file
        or PrintErrorMessage("Cannot copy file $result_file to $output_file: $!");
    $par->newval('RESULT', 'location_txt', $output_file);

    my @modules_by_rundiem = qw \ filter align extract assembly mope vot soot merge location \;
    foreach my $module_by_rundiem ( @modules_by_rundiem) {
        my $result_dir = $par->val('RESULT', $module_by_rundiem);
        if ( $par->val('CDPAN', 'output_level') == 0) {
            $par->delval('RESULT', $module_by_rundiem);
        }
        else {
            my $output_dir = catdir($par->val('CDPAN', 'output_dir'), $module_by_rundiem);
            move $result_dir, $output_dir or PrintErrorMessage("Couln't move $result_dir to $output_dir: $!");
            $par->setval('RESULT', $module_by_rundiem, $output_dir);
        }
    }

    unless ( $par->val('CDPAN', 'output_level') == 0) {
        my $index_dir = $par->val('RESULT', 'ref_index');
        my $index_output_dir = catdir($par->val('CDPAN', 'output_dir'), 'ref_index');
        move $index_dir, $index_output_dir or PrintErrorMessage("Couln't move $index_dir to $index_output_dir: $!");
        $par->delval('RESULT', 'ref_index');

        my $pre_location_dir = $par->val('RESULT', 'pre_location');
        my $pre_location_output_dir = catdir($par->val('CDPAN', 'output_dir'), 'pre_location');
        move $pre_location_dir, $pre_location_output_dir or PrintErrorMessage("Couln't move $pre_location_dir to $pre_location_output_dir: $!");
        $par->delval('RESULT', 'pre_location');
    }

    PrintStartMessage("All modules have been executed for Module RUN-ALL");

    PrintEndMessage("Finish Module RUN-ALL");

    return 1;
};

1;

__END__
