#!/usr/bin/env perl

# Description:
# Author: zhuoy
# Date: 2021-03-03

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Cwd;
use File::Path qw / rmtree /;
use File::Copy qw / move /;
use File::Spec::Functions  qw /:ALL/;
use Config::IniFiles;

use CDpan qw / :ALL /;

#-------------------------------------------------------------------------------
#------------------------------------ START ------------------------------------
#-------------------------------------------------------------------------------
our $version = "0.3.0";
our $date = "Oct 26 2021";

Usage() if @ARGV == 0;

#-------------------------------------------------------------------------------
#---------------------------------- CMD LINE -----------------------------------
#-------------------------------------------------------------------------------
our $cwd = Cwd::getcwd;
our $datestring = localtime();
our $module = shift @ARGV;

if ( $module =~ m/^-/ ) {
    if ( $module eq '-v' or $module eq '--version') {
        PrintExitMessage("CDpan $version $date");
    }elsif ( $module eq '-h' or $module eq '--help') {
        Usage();
    }
}

our %modules = (
    "filter"            => 0,
    "align"             => 0,
    "extract"           => 0,
    "assembly"          => 0,
    "mope"              => 0,
    "vot"               => 0,
    "soot"              => 0,
    "merge"             => 0,
    "location"          => 0,
    "RUN-ALL"           => 0,
    "RUN-DIEM"          => 0,
);

if ( defined $modules{$module} ) {
    $modules{$module} = 1;
} else {
    PrintExitMessage("Invalid module: $module");
}

our $input_dir;
our $config_file;
our $output_prefix;
our $output_dir = $cwd;
our $work_dir = catdir($output_dir,'./cdpan_tmp');
our $output_level = 0;
our $no_quality_control = 0;

while (@ARGV) {
    my $option = shift;

    if    ( $option eq '-i' or $option eq '--input') {
        $input_dir = shift;
        PrintExitMessage("Command \'$option\' is missing parameters\n") if ( ($input_dir // '-' )=~ /^-/ );
        $input_dir =~ s/\/$//;
        $input_dir = rel2abs($input_dir) unless file_name_is_absolute($input_dir);
    }
    elsif ( $option eq '-c' or $option eq '--config') {
        $config_file = shift;
        PrintExitMessage("Command \'$option\' is missing parameters\n") if ( ($config_file // '-' )=~ /^-/ );
        $config_file = rel2abs($config_file) unless file_name_is_absolute($config_file);
    }
    elsif ( $option eq '-w' or $option eq '--work_dir') {
        $work_dir = shift;
        PrintExitMessage("Command \'$option\' is missing parameters\n") if ( ($work_dir // '-' )=~ /^-/ );
        $work_dir =~ s/\/$//;
        $work_dir = rel2abs($work_dir) unless file_name_is_absolute($work_dir);
    }
    elsif ( $option eq '-o' or $option eq '--output') {
        $output_prefix = shift;
        PrintExitMessage("Command \'$option\' is missing parameters\n") if ( ($output_prefix // '-' )=~ /^-/ );
    }
    elsif ( $option eq '-O' or $option eq '--output_dir') {
        $output_dir  = shift;
        PrintExitMessage("Command \'$option\' is missing parameters\n") if ( ($output_dir // '-' )=~ /^-/ );
        $output_dir =~ s/\/$//;
        $output_dir = rel2abs($output_dir) unless file_name_is_absolute($output_dir);
    }
    elsif ( $option eq '-l' or $option eq '--output-level') {
        $output_level = shift;
        PrintExitMessage("Command \'$option\' is missing parameters\n") if ( ($output_level // '-' )=~ /^-/ );
        PrintExitMessage("Command \'$option\' is illegal parameter ( Should be 0, 1 or 2)\n") unless ( ($output_level // '-' )=~ /^[012]$/ );
        $output_level += 0;
    }
    elsif (                    $option eq '--no-qc') {
        $no_quality_control = 1;
    }
    elsif ( $option eq '-v' or $option eq '--version') {
        PrintMessage("CDpan $version $date\n");
        PrintExitMessage();
    }
    elsif ( $option eq '-h' or $option eq '--help') {
        Usage();
    }
    else {
        PrintExitMessage("Invalid command: $option");
    }
}

unless ( defined $input_dir ) {
    PrintExitMessage("Parameter \'input_dir\' is required");
}
$config_file = '' unless defined $config_file;

unless ( defined $output_prefix ) {
    ( undef, undef, $output_prefix ) = splitpath($input_dir);
}

#-------------------------------------------------------------------------------
#------------------------------------ MAIN -------------------------------------
#-------------------------------------------------------------------------------
our $log_file = catfile($output_dir, "$output_prefix.log");
open our $LOG, '>', "$cwd/$output_prefix.log" or PrintErrorMessage("Couldn't create $cwd/$output_prefix.log: $!");

my $main_no_quality_control = $no_quality_control?"True":"False";

PrintMessage("
                     _____  ______
                    /  __ \\ |  _  \\
                    | /  \\/ | | | |  _ __     __ _   _ __
                    | |     | | | | | \'_ \\   / _` | | \'_ \\
                    | \\__/\\ | |/ /  | |_) | | (_| | | | | |
                    \\____/  |___/   | .__/   \\__,_| |_| |_|
                                    | |
                                    |_|

--------------------------------------------------------------------------------

Version:                 $version ( $date )
Runing:                  $datestring

Module :                 $module

Input directory:         $input_dir
Config file:             $config_file
Work directory:          $work_dir
Output directory:        $output_dir
Prefix of output file:   $output_prefix

output level:            $output_level
No quality control:      $main_no_quality_control

log:                     $log_file

");

#-------------------------------------------------------------------------------
#----------------------------------- CHECK -------------------------------------
#-------------------------------------------------------------------------------

our $par;
if ( $config_file ) {
    $par = new Config::IniFiles(-file => $config_file, -allowedcommentchars => '#')
        or PrintErrorMessage("Could not read config file from \'$config_file\': @Config::IniFiles::errors");
}
else{
    $par = new Config::IniFiles();
}
PreProcess($par);

if    ( $modules{ "filter"       } ) { Filter(      $par ); }
elsif ( $modules{ "align"        } ) { Align(       $par ); }
elsif ( $modules{ "extract"      } ) { Extract(     $par ); }
elsif ( $modules{ "assembly"     } ) { Assembly(    $par ); }
elsif ( $modules{ "mope"         } ) { Mope(        $par ); }
elsif ( $modules{ "vot"          } ) { Vot(         $par ); }
elsif ( $modules{ "soot"         } ) { Soot(        $par ); }
elsif ( $modules{ "merge"        } ) { Merge(       $par ); }
elsif ( $modules{ "location"     } ) { Location(    $par ); }
elsif ( $modules{ "RUN-ALL"      } ) { RunAll(      $par ); }
elsif ( $modules{ "RUN-DIEM"     } ) { RunDiem(     $par ); }

rmtree $par->val('CDPAN', 'work_dir') or PrintErrorMessage("Cannot delete work direction: $!");

PrintStartMessage("Output file:");

my @search_res = qw \ filter align extract assembly mope vot soot merge location \;
foreach my $search_res_module (@search_res) {
    if (defined $par->val('RESULT', $search_res_module)){
        PrintfMessage("%-20s", "Module $search_res_module:");
        PrintMessage($par->val('RESULT', $search_res_module));
        PrintMessage("\n");
    }
}

PrintMessage("\n") if (($main::modules{ "RUN-ALL" } or $main::modules{ "RUN-DIEM" }) and $output_level > 0);

if (defined $par->val('RESULT', 'dispensable_genome_fasta')){
    PrintMessage("The result file is saved as: ");
    PrintMessage($par->val('RESULT', 'dispensable_genome_fasta'));
    PrintMessage("\n");
}

if (defined $par->val('RESULT', 'location_txt')){
    PrintMessage("The result file is saved as: ");
    PrintMessage($par->val('RESULT', 'location_txt'));
    PrintMessage("\n");
}

PrintMessage("\n");

move "$cwd/$output_prefix.log", $log_file or PrintErrorMessage("Couln't move $cwd/$output_prefix.log to $log_file: $!");
PrintMessage("The log file is saved as: $log_file\n");

PrintEndMessage("END of CDpan");

close $LOG;
exit 0;


#-------------------------------------------------------------------------------
#----------------------------------- USAGE -------------------------------------
#-------------------------------------------------------------------------------

sub Usage {

print STDERR "
Program: CDpan
Version: $version

Usage: cdpan <module> -i input_dir [options]

Note: To use CDpan, you need to specify a module and a directory of input file. Each sub-directory
      of the input directory should be a separate individual and contain file which will be used
      by the module. CDpan will interpret directory name as individual names. For more information,
      please refer to the manual from https://github.com/kimi-du-bio/CDpan.

Module: filter
        align
        extract
        assembly
        mope
        vot
        soot
        merge
        location

        RUN-ALL         Run all modules of CDpan
        RUN-DIEM        Run all modules of CDpan except location

Options: -i, --input         path of input directory          ( Mandatory )
         -c, --config        path of config file              ( Required by )
         -w, --work_dir      path of work directory           ( Default is \'\${output_dir}/cdpan_tmp\' )
         -l, --output-level  level of detail of the output    ( Default is 0 )
         -o, --output        prefix of the output file        ( Default is name of input directory )
         -O, --output_dir    output directory                 ( Default is the current directory )
             --no-qc         no quality control               ( Default is False )
         -v, --version       print version message
         -h, --help          print help message

";

exit(-1);
}
