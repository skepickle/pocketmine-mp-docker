#!/usr/bin/perl -w
use strict;
use warnings;
use Term::ReadKey;
use IPC::Open3;
use POSIX ":sys_wait_h";
use Time::HiRes qw(sleep);

my ($pm_stdin_h, $pm_stdout_h, $pm_stderr_h);
my $pm_pid = open3($pm_stdin_h, $pm_stdout_h, $pm_stderr_h, '/pm/start.sh --no-wizard')
    or die "open3() failed $!";

#printf("PM STDIN:  %d\n", scalar($pm_stdin_h))  if defined $pm_stdin_h;
#printf("PM STDOUT: %d\n", scalar($pm_stdout_h)) if defined $pm_stdout_h;
#printf("PM STDERR: %d\n", scalar($pm_stderr_h)) if defined $pm_stderr_h;

ReadMode('raw', $pm_stdout_h);
ReadMode('raw', $pm_stderr_h) if defined $pm_stderr_h;
ReadMode('raw');

my $key_pressed = "";
my $key_buffer = "";
my $pm_stdout_buffer = "";
my $pm_stderr_buffer = "";

my $idle = 1;

my $result = 0;

while (1) {
  $idle = 1;

  # Check STDIN for presses ENTER key
  $key_pressed = ReadKey(-1);
  $key_pressed = 0 unless defined $key_pressed;
  last if ($key_pressed eq "q");
  if ($key_pressed eq "\n") {
    $key_pressed = 1;
    $idle        = 0;
  } else {
    $key_pressed = 0;
    $idle        = 0;
  };

  # Pipe full output lines from PocketMine-MP
  if ((defined $pm_stdout_h) &&
      (pipe_lines($pm_stdout_h,$pm_stdout_buffer,'<'))) { $idle = 0; };
  if ((defined $pm_stderr_h) &&
      (pipe_lines($pm_stderr_h,$pm_stderr_buffer,'!'))) { $idle = 0; };

  # If keyboard pressed ENTER earlier, capture a line of input
  if ($key_pressed) {
    ReadMode('normal');
    print ">";
    $key_buffer = <>;
    ReadMode('raw');
  };

  # Pipe full output lines from PocketMine-MP
  if ((defined $pm_stdout_h) &&
      (pipe_lines($pm_stdout_h,$pm_stdout_buffer,'<'))) { $idle = 0; };
  if ((defined $pm_stderr_h) &&
      (pipe_lines($pm_stderr_h,$pm_stderr_buffer,'!'))) { $idle = 0; };

  # Write the line of input from keyboard into PocketMine-MP's STDIN
  if ($key_buffer ne "") {
    printf $pm_stdin_h $key_buffer . "\n";
    $key_buffer = "";
  };

  # Check if PocketMine-MP is still running
  my $res = waitpid($pm_pid, WNOHANG);
  if ($res == -1) {
    $result = $? >> 8;
    printf "Some error occurred %d\n", $result;
    last;
  };
  if ($res) {
    $result = $? >> 8;
    printf "PocketMine-MP ended with error code %d\n", $result;
    my $count_down = 5;
    print "Stopping container in:\n";
    while ($count_down > 0) {
      printf "\t%d%s\n", $count_down, ($count_down>1)?("..."):(".");
      $count_down -= 1;
      sleep(1);
    };
    last;
  };

  sleep(0.1);
};

ReadMode('normal');

close($pm_stdin_h)  if defined $pm_stdin_h;
close($pm_stdout_h) if defined $pm_stdout_h;
close($pm_stderr_h) if defined $pm_stderr_h;

exit($result);

sub pipe_lines {
    my $fh     = $_[0];
    my $buf    = $_[1];
    my $prefix = $_[2];
    my $key    = "";
    my $result = 0;
    $key = ReadKey(-1, $fh);
    while (defined $key) {
      $result = 1;
      $buf .= $key;
      if ($key eq "\n") {
        print $prefix . $buf;
        $buf = "";
      };
      $key = ReadKey(-1, $fh);
    };
    $_[1] = $buf;
    return $result;
};
