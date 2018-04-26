#!/usr/bin/perl
use strict;
use Data::Dumper;
use File::stat;

my $somedir = './';
my $file = $somedir."abc";

my ($gid) = getgrgid(stat($file)->gid);
my ($uid) = getpwuid(stat($file)->uid);

open(FHa, '>', 'FH') or die $!;

print FHa "User Id : $uid Group Id : $gid";
close(FH);
<>
