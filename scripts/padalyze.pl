#!/usr/bin/env perl
# Fetch local copies of all the etherpads -- run this from the /pads directory.
# (It would be nice to also generate a csv file of all pads with fields for 
# number of edits, date of last edit, date created, pad size, number of authors,
# etc.)

use LWP::UserAgent;
use Time::Local;  # more sophisticated packages are Date::Calc and Date::Manip
use POSIX; # ceil and floor
use FindBin '$Bin';

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;  # I don't know what this is for
$ua->ssl_opts(
  SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
  verify_hostname => 0
);

$| = 1;  # autoflush
$server = "padm.us"; # "pad.beeminder.com";
$urlpre = "http://$server/";
$termwidth = `tput cols`; # how wide in characters the terminal is

# The pad hash (%ph) maps padnames to a bitvector (chmod-style, eg) like so:
#   0001  1: pad exists as local file padname.txt
#   0010  2: pad exists in database as pad:padname w/ <= 2 such rows (virgin)
#   0100  4: pad has > 2 "pad:padname" entries in the database (non-virgin)
#   1000  8: pad exists in the database as pad2readonly:padname
# Yielding the following possible values that a padname can map to:
#   0000  0: IMPOSSIBLE (nothing would cause the key to get created)
#   0001  1: orphan (not on server)
#   0010  2: virgin (no local)
#   0011  3: orphan (local version but virginal on server)
#   0100  4: new on server
#   0101  5: normal (both local and on server)
#   0110  6: IMPOSSIBLE (2 and 4 are mutually exclusive)
#   0111  7: IMPOSSIBLE (2 and 4 are mutually exclusive)
#   1000  8: WEIRD -- no local, not on server except as pad2readonly
#   1001  9: orphan but WEIRD -- local exists but only as pad2readonly on server
#   1010 10: virgin (no local)
#   1011 11: orphan (local version but virginal on server)
#   1100 12: new on server
#   1101 13: normal (both local and on server)
#   1110 14: IMPOSSIBLE (2 and 4 are mutually exclusive)
#   1111 15: IMPOSSIBLE (2 and 4 are mutually exclusive)

my @localfiles = glob "*.txt";
my $nl = scalar @localfiles;
for (@localfiles) {
  s/\.txt//;
  $ph{$_} += 1; # 1 (0001) means padname exists as local file padname.txt
}

print splur($nl, "local .txt file") . "; ";
$pads = `$Bin/padlist.sh`;
@padlines = split(/\n/, $pads);
$np = 0;  # number of pads (excluding virgin pads)
$nv = 0;  # number of virgin pads
$nr = 0;  # rows in the database not prefixed with "pad:" (I think)
$ne = 0;  # number of rows in the database prefixed with "pad:" ie total edits

my $headerline = shift @padlines;                 # The first line is the column
if ($headerline !~ /^padname\s+qty\s*$/) {        # labels of the SQL output.
  print "\nERROR! Connectivity trouble? " .
    "First line was as follows instead of matching \"padname qty ...\":\n";
  print $headerline . "\n";
  exit(1);
}
my $countline = shift @padlines;                  # The second line is the total
if ($countline =~ /^\s+(\d+)\s*$/) {              # number of database rows.
  $nr = $1;
} else {
  print "\nLINE 2 SANITY CHECK FAIL: [$countline]\n";
  exit(1);
}

for (@padlines) {
  if (/^pad:(\S+)\s+(\d+)\s*$/) { # padname, whitespace, row count
    $ne += $2;
    if ($2 > 2) { $np++; push(@padlist,    $1); $ph{$1} += 4; } # 4 = 0100
    else        { $nv++; push(@virginlist, $1); $ph{$1} += 2; } # 2 = 0010
  } elsif (/^pad2readonly:(\S+)\s+(\d+)\s*$/) { # similar to "pad:" version
    $ph{$1} += 8; # 8 (1000) means pad exists in DB as pad2readonly:padname
  } else {
    print "\nERROR from padlist.sh: $_\n";  # we don't expect to ever see this
    exit(1);
  }
}
print splur($ne, "edit") . " across all pads, " . 
      splur($nr, "other database row") . "\n";
if ($nv > 0) { 
  printdivider("Not slurping " . splur($nv, "virgin pad")); 
  for(@virginlist) { 
    print "$_ ";
    push(@postv, $_);
  }
  print "\n";
}

#exit(1); # bail out here for dry-run testing without actual pad-slurping

printdivider("Slurping " . splur($np, "non-virgin pad"));
$ne = 0;
$neednewline = 0;
for(@padlist) {
  $ep = $_;
  $localfile = "$ep.txt";
  if(-e $localfile) { 
    $localexists = 1; 
    $localcontent = slurp($localfile);
  } else { $localexists = 0; }
  #$livecontent = get("http://$server/ep/pad/export/$ep/latest?format=txt");
  #$resp = $ua->get("http://$server/ep/pad/export/$ep/latest?format=txt");
  $resp = $ua->get("http://$server/$ep/export/txt");
  if($resp->is_success) {
    $livecontent = $resp->content;
  } else {
    $ne++;
    $errmsg = $resp->status_line;
    $errmsg =~ s/\s+$//;
    print "\nERROR fetching http://$server/$ep/export/txt -- $errmsg\n";
    push(@poste, "$ep -- $errmsg");
    next;
  }
  
  if($livecontent ne $localcontent) { # this used to fail when weird characters
    if($neednewline) { print "\n";  $neednewline = 0; }
    if($livecontent =~ /^\s*$/) { # Blank livecontent could be failure to fetch
      print "NIL $ep\n";          # so don't overwrite local copy (theoretically
      push(@postb, $ep);          # we'd get an error and know not to treat a
    } else {                      # failed fetch as empty contents but...)
      spew($livecontent, $localfile);
      if($localexists) { 
        spew($localcontent, "prev/$localfile");
        $ds = `diff prev/$localfile $localfile`;  # diff string
        unless($termwidth > 2) { $termwidth = 80; }
        if(length("CHG: $ep  $ds") > $termwidth) {
          $ds = `diff prev/$localfile $localfile | diffstat`;
          $ds =~ s/\s*unknown//;
          $ds =~ s/\d+\ files? changed\,\s*//;
        }
        $ds =~ s/\n/ /g;
        print "CHG $ep  $ds\n";  # CHG = CHANGED
        push(@postc, "$ep $ds");
      } else { 
        print "NEW $ep\n"; 
        push(@postn, $ep);
      }
    }
  } else {
    print "$ep ";
    $neednewline = 1;
  }

  # if there's a ^tkl DATE line with DATE not in the future, print it.
  for(split(/\n/, $livecontent)) {
    if(/^tkl\s+(.*)/i && pd($1) <= time()) { 
      if($neednewline) { print "\n";  $neednewline = 0; }
      print "TKL $ep $1\n";
      push(@postt, "$urlpre$ep $1");
      $neednewline = 0;
    }
  }
}
if($neednewline) { print "\n";  $neednewline = 0; }
printdivider(splur($np-$ne, "non-virgin pad") . " slurped (" . 
             splur($ne,     "error") . ")");
$i = 0; for(@poste) { $i++; print "$i ERR $_\n"; } # error fetching from server
$i = 0; for(@postv) { $i++; print "$i VIR $_\n"; } # virgin pad, not slurped
$i = 0; for(@postb) { $i++; print "$i NIL $_\n"; } # blank pad (only whitespace)
$i = 0; for(@postn) { $i++; print "$i NEW $_\n"; } # was no local copy yet
$i = 0; for(@postc) { $i++; print "$i CHG $_\n"; } # changed from local copy
$i = 0; for(@postt) { $i++; print "$i TKL $_\n"; } # tickler reminder due
$i = 0;
keys %ph;
while(my($p,$v) = each %ph) {
  if ($v == 1) {
    $i++;
    print "$i ORF $p (orphaned local file: not on server)\n";
  } elsif ($v == 3 || $v == 11) {
    $i++;
    print "$i ORF $p (orphaned local file: virginal on server)\n";
  } elsif ($v == 9) {
    $i++;
    print "$i ORF $p (orphaned local file: on server only as pad2readonly)\n";
  } elsif ($v == 2 || $v == 4 || $v == 5 || $v == 10 || $v == 12 || $v == 13) {
    # all expected cases, do nothing
  } else { # 0, 6, 7, 14, 15
    print "IMPOSSIBLE ERROR: \$ph{$p} = $v\n";
  }
}

################################################################################
################################## FUNCTIONS ###################################

# Singular/plural
sub splur { my($n, $s, $p) = @_;
  if    ($n == 1)     { return "$n $s";    }
  elsif (defined($p)) { return "$n $p";    }
  else                { return "$n ${s}s"; } 
}

# Print a string surrounded by dashes, assume $termwidth set to terminal width
sub printdivider { my($s) = @_;
  my $nd = $termwidth - length($s) - 2; # number of dashes we want
  my $ndpre  = floor($nd/2);
  my $ndpost = ceil( $nd/2);
  print "-" x $ndpre . " $s " . "-" x $ndpost . "\n"; 
  # for iTerm2, no \n was needed since we're at the edge
}

# Takes filename and returns file contents as a string
sub slurp { my($filename) = @_;
  my $content;
  # The following would work if it weren't for non-ascii chars I think:
  # $content = do {local (@ARGV,$/) = $localfile; <>};
  open(my $fh, '<:encoding(UTF-8)', $filename) or die;  # or just "<:utf8"
  $content = do { local($/); <$fh> };
  close($fh);
  return $content;
}

# Takes a string s and writes it to the file named f
sub spew { my($s, $f) = @_;
  open(F, '>:encoding(UTF-8)', $f) or die "Error writing file $f.";
  print F $s;
  close(F);
}

# Takes pad contents and returns if it's one of the placeholders for new pads
sub virginal { my($s) = @_;
  my $welcome = "Welcome to dreeves's private EtherPad instance";
  $s =~ s/\s+/ /g;
  $s =~ s/^\s*//g;
  $s =~ s/\s*$//g;
  return $s eq "Voila, a new pad. Edit me!" || 
         $s eq "${welcome} Instructions: Start typing!" ||
         $s eq "${welcome}: dtherpad.com Instructions: Start typing!";
}

# Parse Date: must be in year, month, day, hour, min, sec order, returns
#   unix time.
sub pd { my($s) = @_;
  my($year, $month, $day, $hour, $minute, $second);
  
  if($s =~ m{^\s*(\d{1,4})\W*0*(\d{0,2})\W*0*(\d{0,2})\W*0*
                 (\d{0,2})\W*0*(\d{0,2})\W*0*(\d{0,2})\s*.*$}x) {
    #print "DEBUG: $1/$2/$3 T $4:$5:$6\n";
    $year = $1;  $month = $2;   $day = $3;
    $hour = $4;  $minute = $5;  $second = $6;
    #print "DEBUG: ", defined($year), defined($month), defined($day), " ",
    #                 defined($hour), defined($minute), defined($second), "\n";
    $month = 1 unless $month =~ /^\d+$/;       # defaults
    $day = 1 unless $day =~ /^\d+$/;
    $hour |= 0;  $minute |= 0;  $second |= 0;  # defaults
    $year = ($year<100 ? ($year<70 ? 2000+$year : 1900+$year) : $year);
  }
  else {
    ($year,$month,$day,$hour,$minute,$second) =
      (1969,12,31,23,59,59); # indicates couldn't parse it.
  }
  
  # This barfs if you give an impossible date like Feb 30.
  # Eg, Day '30' out of range 1..29 at ./fetchpads.pl line 117.
  return timelocal($second,$minute,$hour,$day,$month-1,$year);
  #return "$year/$month/$day T $hour:$minute:$second\n";
}


# For cleaning up tons of virgin pads (dangerous stuff here that crashes server)
################################################################################
#$i = 0;
#print "\nSLURPING EACH VIRGINAL PAD AFTER ALL -- CLEANUP TIME:\n";
#for(@virginlist) {
#  $i++;
#  $ep = $_;
#  $localfile = "$ep.txt";
#  if(-e $localfile) { 
#    $localexists = 1; 
#    open(my $f, '<:encoding(UTF-8)', $localfile) or die;
#    $localcontent = do { local($/); <$f> };
#    close($f);
#  } else { $localexists = 0; }
#  $resp = $ua->get("http://$server/$ep/export/txt");
#  if($resp->is_success) {
#    $livecontent = $resp->content;
#  } else {
#    print "\nERROR fetching http://$server/$ep/export/txt -- " . 
#      $resp->status_line . "\n";
#    exit(1);
#    #next;
#  }
#
#  if($livecontent ne $localcontent) {
#    if($livecontent =~ /^\s*$/) {
#      print "$i DEBUG BLANK: $ep\n";
#    } elsif (virginal($livecontent) && virginal($localcontent)) {
#      print "$i DEBUG-diff $ep live virginal, local virginal\n";
#      if (-e "prev/$localfile") {
#        print "$i DEBUG: prev/$localfile exists\n";
#        exit(1);
#      }
#    } elsif (virginal($livecontent) && !virginal($localcontent)) {
#      print "$i DEBUG-diff $ep live virginal, local not virginal ***\n";
#    } elsif (!virginal($livecontent) && virginal($localcontent)) {
#      print "$i DEBUG-diff $ep live not virginal, local virginal\n";
#    } else {
#      print "$i DEBUG-diff $ep live not virginal, local not virginal\n";
#      #print "DEBUG $ep (live/local): -------------------------------------\n";
#      #print "$livecontent";
#      #print "-------------------------------------------------------------\n";
#      #print "$localcontent";
#      #print "-------------------------------------------------------------\n";
#    }
#  } else {
#    if (!virginal($livecontent)) {
#      print "$i DEBUG $ep local/live match, not virginal\n";
#    } else {
#      print "$i DEBUG $ep local/live match, VIRGINAL\n";
#      if (-e "prev/$localfile") {
#        print "$i DEBUG $ep prev/$localfile exists\n";
#        exit(1);
#      }
#      if ($ep !~ /^[a-z0-9\-_]+$/) {
#        print "$i DEBUG $ep has weird characters\n";
#        exit(1);
#      }
#      system("mv $localfile graveyard"); # make sure directory graveyard exists
#      print "$i DEBUG: $localfile in graveyard, purging from db on server\n";
#      system("ssh root\@$server /root/paddelete.sh $ep");
#      print "$i DEBUG: $ep is super gone\n";
#      #exit(1);
#      sleep 60;
#    }
#  }
#}
#print "\n";
#exit(1);
################################################################################