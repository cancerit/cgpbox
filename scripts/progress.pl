#!/usr/bin/perl

use strict;
use warnings;
use JSON qw(encode_json);
use Capture::Tiny qw(capture);

my $base_path = shift @ARGV;
my $mt_name = shift @ARGV;
my $wt_name = shift @ARGV;
my $outfile = shift @ARGV;

my @algs = qw(Ref QC ascat pindel caveman brass);
my %alg_elements = (ascat => [qw( allele_count
                                  ascat
                                  finalise)],
                    pindel => [qw(input
                                  pindel
                                  pin2vcf
                                  merge
                                  flag)],
                    caveman => [qw( setup
                                    split
                                    split_concat
                                    mstep
                                    merge
                                    estep
                                    merge_results
                                    add_ids
                                    flag)],
                    brass => [qw( input
                                  cover
                                  merge
                                  group
                                  isize
                                  normcn
                                  filter
                                  split
                                  assemble
                                  grass
                                  tabix)],
                    );

my @algs_list;
for my $alg(@algs) {
  if($alg eq 'Ref' || $alg eq 'QC'){
    push @algs_list, $alg;
  }
  else {
    for my $element(@{$alg_elements}) {
      @algs_list = "$alg.$element";
    }
  }
}

while(1) {
  my %counts;
  for my $alg(@algs) {
    if($alg eq 'Ref') {
      $counts{$alg}{'.'} = ref_testdata_counts($base_path, $mt_name, $wt_name);
    }
    elsif($alg eq 'QC') {
      $counts{$alg}{'.'} = genotype_contam_counts($base_path, $mt_name, $wt_name);
    }
    else {
      for my $element(@{$alg_elements}) {
        $counts{$alg}{$element} = alg_counts($base_path, $alg, $element, $mt_name, $wt_name);
      }
    }
  }
  my ($progress, $last_change) = progress_struct(\%counts);
  open my $OUT, '>', $outfile or die "$!: $outfile";
  print $OUT 'progress = ';
  print $OUT encode_json $progress;
  print $OUT "\n";
  print $OUT qq{last_change = "$last_change"\n};
  close $OUT;

  sleep 28;
}

sub alg_counts {
  my ($base_path, $alg, $element, $mt_name, $wt_name) = @_;
  my $alg_base = sprintf "%s/output/%s_vs_%s/%s", $base_path, $mt_name, $wt_name, $alg;
  my $logs;
  if(-e "$alg_base/logs") {
    $logs = "$alg_base/logs"
  }
  else {
    $logs = "$alg_base/tmp".(ucfirst $alg).'/logs';
  }

  my ($started, $most_recent_log) = file_listing("$logs/*$element.*.err");


  my ($done, $most_recent_prog);
  if(-e "$alg_base/logs") {
    $done = $started if(-e "$alg_base/logs");
  }
  else {
    ($done, $most_recent_prog) = file_listing("$alg_base/tmp".(ucfirst $alg).'/progress/*');
    $done ||= 0;
  }
  my @most_recent;
  push @most_recent, $most_recent_log if(defined $most_recent_log);
  push @most_recent, $most_recent_prog if(defined $most_recent_prog);

  $started = $started - $done;
  return [$started, $done, \@most_recent];
}

sub ref_testdata_counts {
  my ($base_path, @samples) = @_;
  my ($started, $done) = (0,0);
  my @most_recent;

  for my $samp(@samples) {
    # these 2 only occur if pre-exe is test data
    if(-e "$base_path/testdata.tar") {
      $started++;
      $done++ if(-e "$base_path/input/HCC1143.bam");
    }

    #
    if(-e "$base_path/ref.tar.gz") {
      $started++;
      if(-e "$base_path/reference_files") {
        $done++;
        if(-e "$base_path/reference_files/genotype_snps.tsv") {
          $started++;
          $done++ if(-e "$base_path/reference_files/ascat/SnpGcCorrections.tsv");
        }
      }
    }

    $started++ if(-e "$base_path/output/tmp/$samp.bam.bai");
    $done++ if(-e "$base_path/output/tmp/$samp.bam.bas");
    push @most_recent,  "$base_path/output/tmp/$samp.bam.bai",
                        "$base_path/tmp/$samp.bam.bas",
                        "$base_path/testdata.tar",
                        "$base_path/input/HCC1143.bam",
                        "$base_path/ref.tar.gz",
                        "$base_path/reference_files/genotype_snps.tsv",
                        "$base_path/reference_files/ascat/SnpGcCorrections.tsv";
  }
  $started = $started - $done;
  return [$started, $done, \@most_recent];
}

sub genotype_contam_counts {
  my ($base_path, @samples) = @_;
  my ($started, $done) = (0,0);
  my @most_recent;

  for my $samp(@samples) {
    for my $type(qw(contamination genotyped)) {
      $started++ if(-e "$base_path/output/$samp/$type");
      if(-e "$base_path/output/$samp/$type/result.json") {
        $done++;
        push @most_recent, "$base_path/output/$samp/$type/result.json";
      }
    }
  }
  $started = $started - $done;
  return [$started, $done, \@most_recent];
}

sub file_listing {
  my ($search) = @_;
  my ($stdout, $stderr, $exit) = capture { system("ls -ltrh $search"); };
  my @lines = split /\n/, $stdout;
  my $count = 0;
  my ($most_recent_file, $most_recent_dt);
  for my $line(@lines) {
    chomp $line;
    my @elements = split / +/, $line;
    next unless(scalar @elements == 9);
    $count++;
    $most_recent_file = $elements[-1];
    $most_recent_dt = join ' ', $elements[-4], $elements[-3], $elements[-2];
  }
  return ($count, $most_recent_file, $most_recent_dt);
}

sub progress_struct {
  my $counts = shift;

  my (@started, @done, @files);
  for my $alg(@algs_list) {
    my ($base, $element) = split /./, $alg;
    $element ||= '.';
    push @started, $counts->{$base}->{$element}->[0] || 0;
    push @done, $counts->{$base}->{$element}->[1] || 0;
    push @files, @{$counts->{$base}->{$element}->[2]};
  }
  my $progress = {
    labels => \@algs_list,
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

  my (undef, undef, $dt) = file_listing(join ' ', @files);
  return ($progress, $dt);
}
