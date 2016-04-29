#!/usr/bin/perl

use strict;
use warnings;
use JSON qw(encode_json);

my $base_path = shift @ARGV;
my $mt_name = shift @ARGV;
my $wt_name = shift @ARGV;
my $outfile = shift @ARGV;

my @algs = qw(QC ascat pindel caveman brass);

while(1) {
  my %counts;
  for my $alg(@algs) {
    if($alg eq 'QC') {
      $counts{$alg} = genotype_contam_counts($base_path, $mt_name, $wt_name);
    }
    else {
      $counts{$alg} = alg_counts($base_path, $alg, $mt_name, $wt_name);
    }
  }
  my $progress = progress_struct(\%counts);
  open my $OUT, '>', $outfile or die $!;
  print $OUT 'progress = ';
  print $OUT encode_json $progress;
  print $OUT "\n";
  close $OUT;

  die "Artifical stop";

  sleep 28;
}

sub alg_counts {
  my ($base_path, $alg, $mt_name, $wt_name) = @_;
  my ($started, $done) = (0,0);
  my $alg_base = sprintf "%s/%s_vs_%s/%s", $base_path, $mt_name, $wt_name, $alg;
  my $logs;
  if(-e "$alg_base/logs") {
    $logs = "$alg_base/logs"
    # when this starts, set completed ==
  }
  else {
    $logs = "$alg_base/tmp".(ucfirst $alg).'/logs';
  }
warn "NOT DONE";
  $done = $started if(-e "$alg_base/logs");
  $started = $started - $done;
  return {$element => [$started, $done]};
}

sub genotype_contam_counts {
  my ($base_path, @samples) = @_;
  my ($started, $done) = (0,0);
  for(@samples) {
    $started++ if(-e "$base_path/$_/genotyped");
    $done++ if(-e "$base_path/$_/genotyped/result.json");
    $started++ if(-e "$base_path/$_/genotyped");
    $done++ if(-e "$base_path/$_/contamination/result.json");
  }
  $started = $started - $done;
  return [$started, $done];
}

sub progress_struct {
  my $counts = shift;
  my (@started, @done);
  for my $alg(@algs) {
    push @started, $counts->{$alg}->[0] || 0;
    push @done, $counts->{$alg}->[1] || 0;
  }
  my $progress = {
    labels => \@algs,
    datasets => [
      {
        label => "Jobs Started",
        backgroundColor => "rgba(255,99,132,0.2)",
        borderColor => "rgba(255,99,132,1)",
        borderWidth => 1,
        hoverBackgroundColor => "rgba(255,99,132,0.4)",
        hoverBorderColor => "rgba(255,99,132,1)",
        data => \@started,
      },
      {
        label => "Jobs Completed",
        backgroundColor => "rgba(75,192,192,0.2)",
        borderColor => "rgba(75,192,192,1)",
        borderWidth => 1,
        hoverBackgroundColor => "rgba(75,192,192,0.4)",
        hoverBorderColor => "rgba(75,192,192,1)",
        data => \@done,
      }
    ]
  };
  return $progress;
}
