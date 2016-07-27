#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw(first max);
use JSON qw(encode_json);
use Capture::Tiny qw(capture);
use Cwd 'abs_path';
use DateTime;

my $dt_format = '%F %T';

my $base_path = shift @ARGV;
my $mt_name = shift @ARGV;
my $wt_name = shift @ARGV;
my $timezone = shift @ARGV;
my $outfile = shift @ARGV;

my $min_epoch = time;
my $max_cpus = max_cpu();

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
my @file_ignores = qw(Sanger_CGP_Ascat_Implement_ascat.merge_counts_);

my $cgpbox_ver = q{-};
$cgpbox_ver = $ENV{CGPBOX_VERSION} if(exists $ENV{CGPBOX_VERSION});

my $load_trend = [[],[],[],[]];

my $started_at = DateTime->now->set_time_zone($timezone)->strftime($dt_format);

while (1) {
  my ($ref_status, $ref_mod) = setup_status($base_path);
  my ($testdata_status, $testdata_mod) = testdata_status($base_path);
  my ($qc_status, $qc_mod) = qc_status($base_path, $mt_name, $wt_name);

  my @mods = ($min_epoch, # this ensures that archive files can't give daft time-points
              $ref_mod,$testdata_mod,$qc_mod);

  my $complete_dt = completed($base_path, $mt_name, $wt_name);

  open my $OUT, '>', $outfile or die "$!: $outfile";

  # encoded variables
  for my $alg(@algs) {
    my (@running, @completed, @labels);
    for my $element(@{$alg_elements{$alg}}) {
      my ($started, $done, $recent) = alg_counts($base_path, $alg, $element, $mt_name, $wt_name);
      push @running, 0+$started;
      push @completed, 0+$done;
      push @mods, $recent;
      push @labels, $element;
    }
    print $OUT sprintf "%s = %s;\n", $alg, encode_json ${progress_struct($alg, \@running, \@completed, \@labels)};
  }

  # all the simple string variables
  print $OUT sprintf qq{%s = "%s";\n}, 'cgpbox_ver', $cgpbox_ver;
  print $OUT sprintf qq{%s = "%s";\n}, 'mt_name', $mt_name;
  print $OUT sprintf qq{%s = "%s";\n}, 'wt_name', $wt_name;
  print $OUT sprintf qq{%s = "%s";\n}, 'setup_status', $ref_status;
  print $OUT sprintf qq{%s = "%s";\n}, 'testdata_status', $testdata_status;
  print $OUT sprintf qq{%s = "%s";\n}, 'qc_status', $qc_status;
  print $OUT sprintf qq{%s = "%s";\n}, 'last_change', recent_date_from_epoch( \@mods );
  print $OUT sprintf qq{%s = "%s";\n}, 'total_cpus', $max_cpus;
  print $OUT sprintf qq{%s = "%s";\n}, 'started_at', $started_at;
  print $OUT sprintf qq{%s = "%s";\n}, 'completed_at', $complete_dt;
  print $OUT sprintf qq{%s = "%s";\n}, 'load_avg', load_avg($load_trend);

  print $OUT sprintf qq{load_trend = %s;\n}, encode_json ${trend_struct($load_trend)};

  close $OUT;

  if($complete_dt ne q{-}) {
    print "Workflow completed, shutting down monitoring\n";
    exit 0;
  }

  sleep 30;
}

sub completed {
  my ($base_path, $mt_name, $wt_name) = @_;
  my $logs_moved = 0;
  for my $alg(@algs) {
    my $alg_base = sprintf "%s/output/%s_vs_%s/%s", $base_path, $mt_name, $wt_name, $alg;
    $logs_moved++ if(-e "$alg_base/logs");
  }
  my $ret = q{-};
  $ret = DateTime->now->set_time_zone($timezone)->strftime($dt_format) if($logs_moved == @algs);
  return $ret;
}

sub trend_struct {
  my $trends = shift;
  my $max_points = scalar @{$trends->[0]};
  if($max_points > 240) {
    shift @{$trends->[0]};
    shift @{$trends->[1]};
    shift @{$trends->[2]};
    shift @{$trends->[3]};
  }

  my $thin_level = 2;
  my $datapoints = @{$trends->[3]};
  if($datapoints > 180) {
    $thin_level = 18;
  }
  elsif($datapoints > 120) {
    $thin_level = 12;
  }
  elsif($datapoints > 60) {
    $thin_level = 6;
  }
  elsif($datapoints > 30) {
    $thin_level = 4;
  }
  my @thinned;
  my $skipped = $thin_level-1;
  for(@{$trends->[3]}) {
    $skipped++;
    if($skipped == $thin_level) {
      $skipped = 0;
      push @thinned, $_;
    }
    else {
      push @thinned, q{};
    }
  }

  my $trend = {
    type => 'line',
    options => {
      animation => {'duration' => 0},
      title => {
        display => 'true',
        text => 'Server Load (max 2h)',
        fontStyle => ''
      },
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
            suggestedMax => $max_cpus,
            suggestedMin => 0,
          }
        }],
        xAxes => [{
          ticks => {
            'autoSkip' => 0
          }
        }],
      }
    },
    data => {
      labels => \@thinned,
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
          borderColor => 'rgba(53,88,161,1)',
          backgroundColor => 'rgba(53,88,161,0)',
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
  my ($alg, $running, $completed, $labels) = @_;
  my @cleaned_labels;
  for(@{$labels}) {
    if($_ eq 'merge_results') {
      $_ = 'm_result';
    }
    else {
      $_ =~ s/^caveman_//;
    }

    push @cleaned_labels, $_;
  }
  my $progress = {
    type => 'bar',
    options => {
      animation => {'duration' => 0},
      title => {
        display => 'true',
        text => ucfirst $alg,
        fontStyle => ''
      },
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
      labels => \@cleaned_labels,
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
          backgroundColor => 'rgba(53,88,161,0.2)',
          borderColor => 'rgba(53,88,161,1)',
          borderWidth => 1,
          hoverBackgroundColor => 'rgba(53,88,161,0.4)',
          hoverBorderColor => 'rgba(53,88,161,1)',
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
  return DateTime->from_epoch( epoch => $max )->set_time_zone($timezone)->strftime($dt_format)
}

sub get_most_recent {
  my ($most_recent, $file) = @_;
  if(-e $file) {
    my $epoch = (stat $file)[9];
    $most_recent = $epoch if($epoch > $most_recent);
  }
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

  my $dt = DateTime->now->truncate(to => "minute")->set_time_zone($timezone)->strftime('%R');
#  $dt = q{} if(@{$trend->[3]} != 0 && $trend->[3]->[-1] eq $dt);
  push @{$trend->[3]}, $dt;

  return sprintf '%s/%s/%s',$one_min, $five_min, $ten_min;
}

sub max_cpu {
  my ($stdout, $stderr, $exit) = capture { system('grep -c ^processor /proc/cpuinfo'); };
  chomp $stdout;
  return $stdout+0;
}

sub file_listing {
  my ($search) = @_;
  my @files = glob $search;
  my $count = @files;
  my $most_recent = 0;
  for my $file(@files) {
    next if(first {$_ =~ m/$file/} @file_ignores);
    $most_recent = get_most_recent($most_recent, $file);
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

  my ($started, $most_recent_log) = file_listing("$logs/*_$element.*.err");

  my ($done, $most_recent_prog);
  if(-e "$alg_base/logs") {
    $done = $started;
  }
  else {
    ($done, $most_recent_prog) = file_listing("$alg_base/tmp".(ucfirst $alg)."/progress/*_$element.*");
    $done ||= 0;
  }

  $most_recent_log ||= 0;
  $most_recent_prog ||= 0;
  my $most_recent = max($most_recent_log, $most_recent_prog);

  $started ||= 0;
  $done ||= 0;

  $started = $started - $done;
  return ($started, $done, $most_recent);
}

sub qc_status {
  my ($base_path, @samples) = @_;
  my ($started, $done) = (0,0);
  my $most_recent = 0;
  my $status = 'Pending';

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
      $status = 'Completed';
    }
    else {
      $status = 'Started';
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
    $most_recent = get_most_recent($most_recent, "$base_path/testdata.tar");
    my (undef, $most_recent_unpack) = file_listing("$base_path/input/*.cram", "$base_path/input/*.bam*");
    $most_recent = $most_recent_unpack if($most_recent_unpack > $most_recent);
    if(-e "$base_path/input/$mt_name.bam" && -e "$base_path/input/$wt_name.bam") {
      $done++;
    }
    if($started > 0) {
      if($done == $started) {
        $status = 'Completed';
      }
      else {
        $status = 'Started';
      }
    }
  }
  return ($status, $most_recent);
}

sub setup_status {
  my ($base_path) = @_;
  my ($started, $done) = (0,0);
  my $most_recent = 0;

  $base_path .= '/'.$cgpbox_ver;

  if(-e "$base_path/reference_files/unpack_ref.success") {
    my $this = get_most_recent($min_epoch, "$base_path/reference_files/unpack_ref.success");
    if($this == $min_epoch) {
      return ('Pre-staged', get_most_recent($most_recent, "$base_path/reference_files/unpack_ref.success"));
    }
  }

  if(-e "$base_path/ref.tar.gz") {
    $started++;
    $most_recent = get_most_recent($most_recent, "$base_path/ref.tar.gz");
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

  my $status = 'Pending';
  if($started > 0) {
    if($done == $started) {
      $status = 'Completed';
    }
    else {
      $status = 'Started';
    }
  }
  return ($status, $most_recent);
}
