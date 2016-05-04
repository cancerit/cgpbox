#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw(max);
use JSON qw(encode_json);
use Capture::Tiny qw(capture);

my $base_path = shift @ARGV;
my $mt_name = shift @ARGV;
my $wt_name = shift @ARGV;
my $outfile = shift @ARGV;

my $min_epoch = time;
my $max_cpus = max_cpu();

my @time_legend = ('Now');
for(1..120) {
  if($_%20 == 0) {
    unshift @time_legend, (0-$_)/2;
  }
  else {
    unshift @time_legend, q{};
  }
}

my @algs = qw(ascat pindel caveman brass);
my %alg_elements = (ascat => [qw( allele_count
                                  ascat
                                  finalise)],
                    pindel => [qw(input
                                  pindel
                                  pindel_to_vcf
                                  merge_and_bam
                                  flag)],
                    caveman => [qw( caveman_setup
                                    caveman_split
                                    concat
                                    caveman_mstep
                                    caveman_merge
                                    caveman_estep
                                    caveman_merge_results
                                    caveman_add_ids
                                    caveman_flag)],
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

my $load_trend = [[(0)x120],[(0)x120],[(0)x120]];

while (1) {
  my ($ref_status, $ref_mod) = setup_status($base_path);
  my ($testdata_status, $testdata_mod) = testdata_status($base_path);
  my ($qc_status, $qc_mod) = qc_status($base_path, $mt_name, $wt_name);

  my @mods = ($min_epoch, # this ensures that archive files can't give daft time-points
              $ref_mod,$testdata_mod,$qc_mod);

  open my $OUT, '>', $outfile or die "$!: $outfile";
  print $OUT qq{setup_status = "$ref_status"\n};
  print $OUT qq{testdata_status = "$testdata_status"\n};
  print $OUT qq{qc_status = "$qc_status"\n};

  for my $alg(@algs) {
    my (@running, @completed, @labels);
    for my $element(@{$alg_elements{$alg}}) {
      my ($started, $done, $recent) = alg_counts($base_path, $alg, $element, $mt_name, $wt_name);
      push @running, $started;
      push @completed, $done;
      push @mods, $recent;
      $element =~ s/^caveman_//;
      push @labels, $element;
    }
    print $OUT sprintf "%s = %s\n", $alg, encode_json ${progress_struct(\@running, \@completed, \@labels)};
  }

  print $OUT sprintf qq{last_change = "%s"\n}, recent_date_from_epoch( \@mods );
  print $OUT sprintf qq{load_avg = "%s (cores=%d)"\n}, load_avg($load_trend), $max_cpus;
  print $OUT sprintf "%s = %s\n", 'load_trend', encode_json ${trend_struct($load_trend)};

  close $OUT;

  sleep 30;
}

sub trend_struct {
  my $trends = shift;
  my $max_points = scalar @{$trends->[0]};
  if($max_points > 120) {
    shift $trends->[0];
    shift $trends->[1];
    shift $trends->[2];
  }

  my $trend = {
    type => 'line',
    options => {
      elements => {
        point => {
          radius => 0,
          hoverRadius => 5,
        }
      },
      scales => {
        yAxes => [{
          type => 'linear',
          ticks => {
            beginAtZero => 'true',
            stepSize => 1,
          }
        }]
      }
    },
    data => {
      labels => \@time_legend,
      datasets => [
        { data => $trends->[0],
          label => '1-min',
          borderWidth => 1,
          tension => 0.3,
          borderColor => 'rgba(255,99,132,1)',
          backgroundColor => 'rgba(255,99,132,0)',
        },
        { data => $trends->[1],
          label => '5-min',
          borderWidth => 1,
          tension => 0.3,
          borderColor => 'rgba(75,192,192,1)',
          backgroundColor => 'rgba(75,192,192,0)',
        },
        { data => $trends->[2],
          label => '10-min',
          borderWidth => 1,
          tension => 0.3,
          borderColor => 'rgba(179,181,198,1)',
          backgroundColor => 'rgba(179,181,198,0)',
        },
      ]
    }
  };
  return \$trend;
}

sub progress_struct {
  my ($running, $completed, $labels) = @_;;
  my $progress = {
    type => 'bar',
    options => {
      scales => {
        xAxes => [{
          stacked => 'true'
        }],
        yAxes => [{
          scaleLabel => {
            display => 'true',
            labelString => 'Jobs',
          },
          stacked => 'true',
          type => 'linear',
          ticks => {
            suggestedMax => 10,
            suggestedMin => 0,
          }
        }]
      }
    },
    data => {
      labels => $labels,
      datasets => [
        {
          label => 'Started',
          backgroundColor => 'rgba(255,99,132,0.2)',
          borderColor => 'rgba(255,99,132,1)',
          borderWidth => 1,
          hoverBackgroundColor => 'rgba(255,99,132,0.4)',
          hoverBorderColor => 'rgba(255,99,132,1)',
          data => $running,
        },
        {
          label => 'Completed',
          backgroundColor => 'rgba(75,192,192,0.2)',
          borderColor => 'rgba(75,192,192,1)',
          borderWidth => 1,
          hoverBackgroundColor => 'rgba(75,192,192,0.4)',
          hoverBorderColor => 'rgba(75,192,192,1)',
          data => $completed,
        }
      ]
    }
  };
  return \$progress;
}

sub recent_date_from_epoch {
  my ($epochs) = @_;
  my $max =  max @{$epochs};
  return '-' unless(defined $max);
  return scalar localtime $max;
}

sub get_most_recent {
  my ($most_recent, $file) = @_;
  my $epoch = (stat $file)[9];
  $most_recent = $epoch if($epoch > $most_recent);
  return $most_recent;
}

sub load_avg {
  my $trend = shift;
  my ($stdout, $stderr, $exit) = capture { system('uptime'); };
  chomp $stdout;
  my ($one_min, $five_min, $ten_min) = $stdout =~ m/[^0-9]+([0-9]+\.[0-9]{2})[^0-9]+([0-9]+\.[0-9]{2})[^0-9]+([0-9]+\.[0-9]{2})$/;
  push @{$trend->[0]}, $one_min;
  push @{$trend->[1]}, $five_min;
  push @{$trend->[2]}, $ten_min;
  return sprintf '%s/%s/%s',$one_min, $five_min, $ten_min;
}

sub max_cpu {
  my ($stdout, $stderr, $exit) = capture { system('grep -c ^processor /proc/cpuinfo'); };
  chomp $stdout;
  return $stdout+0;
}

sub file_listing {
  my ($search) = @_;
  my ($stdout, $stderr, $exit) = capture { system("ls -ltrh $search"); };
  my @lines = split /\n/, $stdout;
  my $count = 0;
  my $most_recent = 0;
  for my $line(@lines) {
    chomp $line;
    my @elements = split / +/, $line;
    next unless(scalar @elements == 9);
    $count++;
    $most_recent = get_most_recent($most_recent, $elements[-1]);
  }
  return ($count, $most_recent);
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


  my ($started, $most_recent_log) = file_listing("$logs/*::$element.*.err");

  my ($done, $most_recent_prog);
  if(-e "$alg_base/logs") {
    $done = $started;
  }
  else {
    ($done, $most_recent_prog) = file_listing("$alg_base/tmp".(ucfirst $alg)."/progress/*::$element.*");
    $done ||= 0;
  }

  $most_recent_log ||= 0;
  $most_recent_prog ||= 0;
  my $most_recent = max($most_recent_log, $most_recent_prog);

  $started = $started - $done;
  return ($started+0, $done+0, $most_recent);
}

sub qc_status {
  my ($base_path, @samples) = @_;
  my ($started, $done) = (0,0);
  my $most_recent = 0;
  my $status = 'pending';

  for my $samp(@samples) {
    for my $type(qw(contamination genotyped)) {
      if(-e "$base_path/output/$samp/$type") {
        $started++;
        if(-e "$base_path/output/$samp/$type/result.json") {
          $done++;
          $most_recent = get_most_recent($most_recent, "$base_path/output/$samp/$type/result.json");
        }
      }
    }
  }

  if($started > 0) {
    if($done == 3 && $done == $started) {
      $status = 'done';
    }
    else {
      $status = 'started';
    }
  }
  return ($status, $most_recent);
}

sub testdata_status {
  my ($base_path) = @_;
  my $status = 'N/A';
  my $most_recent = 0;
  # these 2 only occur if pre-exe is test data
  if(-e "$base_path/testdata.tar") {
    my ($started, $done) = (0,0);
    $started++;
    if(-e "$base_path/input/HCC1143.bam") {
      $done++;
      $most_recent = get_most_recent($most_recent, "$base_path/input/HCC1143.bam");
    }
    if($started > 0) {
      if($done == $started) {
        $status = 'done';
      }
      else {
        $status = 'started';
      }
    }
  }
  return ($status, $most_recent);
}

sub setup_status {
  my ($base_path) = @_;
  my ($started, $done) = (0,0);
  my $most_recent = 0;
  if(-e "$base_path/ref.tar.gz") {
    $started++;
    if(-e "$base_path/reference_files") {
      $done++;
      $most_recent = get_most_recent($most_recent, "$base_path/reference_files");
      if(-e "$base_path/reference_files/genotype_snps.tsv") {
        $started++;
        if(-e "$base_path/reference_files/ascat/SnpGcCorrections.tsv") {
          $done++;
          $most_recent = get_most_recent($most_recent, "$base_path/reference_files/ascat/SnpGcCorrections.tsv");
        }
      }
    }
  }

  my $status = 'pending';
  if($started > 0) {
    if($done == $started) {
      $status = 'done';
    }
    else {
      $status = 'started';
    }
  }
  return ($status, $most_recent);
}
