#!/usr/bin/perl
#
#	parse_srt.pl
#	XBMC Language Filter
#
#	Created by Brock Haymond 9/6/12.
#	Copyright (c) 2012 Brock Haymond <http://brockhaymond.com>.  All rights reserved.
#
# 	Perl script to search a subtitle.srt file for profanity and create an XBMC-compatible EDL file from the results found.
# 	You can call the perl script as follows:
#
#	perl parse_srt.pl "subtitle_file.srt"
#
#	The "subtitle_file.edl" file will be output into the same directory as the original subtitle.srt file.
#

use Time::Seconds;
use Cwd 'chdir';
use File::Basename;

if($ARGV[$0] eq "") {
	print "Usage: perl parse_srt.pl --offset=seconds --pad=seconds [subtitle.srt]\n";
	print "Output: subtitle.edl\n";
	exit 1;
}

my $verbose = 0;

$cwd = $ENV{PWD};
chdir dirname $0;

if(!open PROFM, "pmatch.txt") {print "Couldn't open profanities match file: $!.\r\n"; exit 1;}
@pmatch = <PROFM>;
chomp(@pmatch);
our %pmatchhash = map { $_ => 1 } @pmatch;
close(PROFM);

if(!open PROFC, "pcontains.txt") {print "Couldn't open profanities contains file: $!.\r\n"; exit 1;}
@pcontains = <PROFC>;
chomp(@pcontains);
close(PROFC);

chdir $cwd;

$offset = $ARGV[0];
$offset =~ s/--offset=//;
$offset = int($offset);

$pad = $ARGV[1];
$pad =~ s/--pad=//;
$pad = int($pad);

$file = $ARGV[2];
$edl = $file;
$edl =~ s/srt/edl/;

if(!open TXT, "$file") {print "Couldn't open file '$file:' $!.\r\n"; exit 1;}
if(!open EDL, ">$edl") {print "$!\r\n"; exit 1;}

if($verbose) {print "Processing $file\nWriting to $edl\n";}

undef $/;
$file = <TXT>;
$file =~ s/\r\n/\n/g;

my @block = split('\n\n', $file);
foreach $block (@block) {
  my @lines = split('\n', $block);
  $block =~ s/^(?:.*\n){1,2}//;
  $block =~ s/,|\.|\?|\!|"|#|:|\<.*?\>|\[(.*|.*\n.*)\]//g;
  $block =~ s/-/ /g;
  $block =~ s/  / /g;

  $found = 0;
  $found |= ($block =~ /.*$_.*/i) foreach (@pcontains);

  my @words = split(' ', $block);
  $found |= exists $pmatchhash{lc($_)} foreach (@words);

  if($found) {
	  #print "$lines[1]\n$block\n\n";
	  $lines[1] =~ s/,/\./g;
    my @times = split(' --> ', $lines[1]);
	  $start = parsetime($times[0], $offset - $pad);
    $end = parsetime($times[1], $offset + $pad);
    print EDL "$start\t$end\t1\r\n";
  }
}

if($verbose) {print "Finished parsing $ARGV[$0]\n";}

sub parsetime {
  my $offset = $_[1];
  my @time = split(':', $_[0]);
  $time = $time[0]*3600 + $time[1]*60 + $time[2] + $offset;
  my $hours = int($time / 3600); $time = $time % 3600;
  my $minutes = int($time / 60); $time = $time % 60;
  my $seconds = $time;
  return sprintf "%02d:%02d:%02d", $hours, $minutes, $seconds;
}

close(TXT);
close(EDL);

if($verbose) {print "Closed $ARGV[$0]\nClosed $edl\n";}
