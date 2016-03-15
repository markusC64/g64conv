#!/usr/bin/perl

### Do not remove the following lines, they ensure that
### perl2exe (http://www.perl2exe.com ) can be used to
### make an executable tha does not need an installed
### version of perl.

#perl2exe_include "PerlIO.pm"
#perl2exe_include "PerlIO/scalar.pm"
#perl2exe_include "utf8.pm"
#perl2exe_include "unicore/Heavy.pl"
#perl2exe_include "unicore/lib/Perl/_PerlIDS.pl"

use strict;

if (@ARGV < 2)
{
   die "Syntax: g64conv.pl <from.g64> <to.txt> [mode]\n".
       "        g64conv.pl <from.txt> <to.g64>\n".
       "        g64conv.pl <from.d64> <to.g64>\n".
       "        g64conv.pl <fromTemplate.txt> <to.g64> <from.d64>\n".
       "mode may be 0 (hex only) or 1 (gcr parsed, default).\n";
}


my $from = $ARGV[0];
my $to = $ARGV[1];
my $level = $ARGV[2];

if ($from =~ /\.g64$/i && $to =~ /\.txt$/)
{
   $level = 1 unless defined $level;
   my $g64 = readfileRaw($from);
   my $txt = g64totxt($g64, $level);
   writefile($txt, $to);
}
elsif ($from =~ /\.d64$/i && $to =~ /\.g64$/)
{
   my $txt = stddisk();
   my $d64 = readfile($from);
   my $g64 = txttog64($txt, $d64);
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.txt$/i && $to =~ /\.g64$/)
{
   my $txt = readfile($from);
   my $d64 = undef;
   $d64 = readfileRaw($level) if defined $level;
   my $g64 = txttog64($txt, $d64);
   writefileRaw($g64, $to);
}
else
{
   die "Unknown conversion\n";
}



sub readfile
{
   my $filename = $_[0];
   my $file;
   local $/;
   undef $/;
   open($file, "<", $filename) or die "Canno read file\n";
   my $ret = <$file>,
   close $file;
   $ret;
}

sub readfileRaw
{
   my $filename = $_[0];
   my $file;
   local $/;
   undef $/;
   open($file, "< :raw", $filename) or die "Canno read file\n";
   my $ret = <$file>,
   close $file;
   $ret;
}

sub writefile
{
   my ($content, $filename) = @_;

   my $file;
   open($file, ">", $filename) or die "Canno write file\n";
   print $file $content;
   close $file;
}

sub writefileRaw
{
   my ($content, $filename) = @_;

   my $file;
   open($file, "> :raw", $filename) or die "Canno write file\n";
   print $file $content;
   close $file;
}

sub g64totxt
{
   my ($g64, $level) = @_;
   my $ret = "";
   
   my $signature = substr($g64, 0, 8);
   return undef unless $signature eq 'GCR-1541';

   return undef unless substr($g64, 8, 1) eq "\0";
   
   my $notracks = unpack("C", substr($g64, 9, 1));
   my $tracksizeHdr = unpack("S", substr($g64, 0xA, 2));
   
   $ret .= "no-tracks $notracks\ntrack-size $tracksizeHdr\n";
   for (my $i=1; $i<$notracks; $i++)
   {
      my $track = ($i+1)/2;
      my $trackTablePosition = 8+4*$i;
      my $trackPosition = unpack("L", substr($g64, $trackTablePosition, 4));
      next unless $trackPosition;
      my $trackSize = unpack("S", substr($g64, $trackPosition, 2));
      my $trackContent = substr($g64, $trackPosition+2, $trackSize);
      
      my $trackContentHex = unpack("H*", $trackContent);
      $trackContentHex =~ s/(..)/ $1/gc;
      
      my $speedTableOffset = 8+4*$notracks + 4*$i;
      my $speed = unpack("L", substr($g64, $speedTableOffset, 4));
      
      my $trackRet = "track $track\n";
      if ($level == 0)
      {
         $trackRet .= "   speed $speed\n   bytes$trackContentHex\n";
	 $trackRet .= "end-track\n\n";
      }
      else
      {
         my $tmp = $trackContentHex;
	 $tmp =~ s/ //g;
         my $trackBin = pack("H*", $tmp);
	 my $trackContentBin = unpack("B*", $trackBin);
	 
         $tmp = parseTrack($trackContentBin);
         $trackRet .= "   speed $speed\n";
	 unless (defined $tmp)
	 {
	    $tmp = "   begin-at 0\n   bytes$trackContentHex\n";
	    $tmp .= "end-track\n\n";
	 }
	 
	 $trackRet .= $tmp;
      }
      
      $ret .= $trackRet;
   }
   
   
   $ret;
}

sub parseTrack
{
   my $track = $_[0];
   
   my $ret;
   my $beginat;
   
   unless ($track =~ /^(.*?)(1111111111)(.*)$/ )
   {
      return undef;
   }

   $track = "$2$3$1";
   $beginat = length($1);
   
   if ($track =~ m/^(1+0101010111.*?)(1{9}.*)$/ )
   {
      my $offset = length($1);
      $track = "$2$1";
      $beginat += $offset;
   }
   
   $track =~ m/^(1{8})(.*)/;
   $track = "$2$1";
   $beginat += 8;

   if ($track =~m/^(.*?)(1{9})(1+)$/)
   {
      my $offset = length($3);
      $track = "$3$1$2";
      $beginat -= $offset;
      $beginat += length($track) if $beginat < 0;
   }
   
   $ret .= "   begin-at $beginat\n";
   
   while ($track ne "")
   {
      # Remark: No need to test for > 9 bits cause we arranged that $track is starting with sync
      # which is continued from last "trackPart"!
      $track =~ s/^(1+)//;
      $ret .= "   sync " . length($1) . "\n";
      my $trackPart;
      my $trackRest;
      
      if ($track =~ m/^(.*?1{9})(1.*)$/)
      {
         $trackPart = $1;
	 $trackRest = $2;
      }
      else
      {
         $trackPart = $track;
	 $trackRest = "";
      }
      
      my $v1 = $trackPart =~ s/^(.{5})//;
      my $c = $1;
      unless ($v1)
      {
         $c = $trackPart;
	 $trackPart = "";
      }
      my $a = parseGCR($c);
      my $v2 = $trackPart =~ s/^(.{5})//;
      my $d = $1;
      unless ($v2)
      {
         $d = $trackPart;
	 $trackPart = "";
      }
      my $b = parseGCR($d);

      if ($a.$b eq '08')
      {
         $ret .= "   ; header\n";
         $ret .= "   gcr 08\n";
	 
	 my $trk = undef;
	 my $sec = undef;
	 
         for (my $i=0; $i<7; $i++)
	 {
            my $v3 = $trackPart =~ s/^(.{5})//;
	    unless ($v3)
	    {
                  $ret .= ";   block aborted\n";
		  last;	       
	    }
	    my $e = $1;
            my $a = parseGCR($1);
            my $v4 = $trackPart =~ s/^(.{5})//;
	    unless ($v4)
	    {
		  $ret .= "   bits $e\n";
                  $ret .= ";   block aborted\n";
		  last;	       
	    }
	    my $f = $1;
            my $b = parseGCR($1);
	    
	    if ($i == 0)
	    {
	       $ret .= "   begin-checksum\n";
	       $ret .= "      checksum $a$b\n" if (defined $a) && (defined $b);
	       $ret .= "      checksum $e$f\n" unless (defined $a) && (defined $b);
	    }
	    else
	    {
	       $ret .= "      ; sector\n" if $i == 1;
	       $ret .= "      ; track\n" if $i == 2;
	       $ret .= "      ; id2\n" if $i == 3;
	       $ret .= "      ; id1\n" if $i == 4;
	       if ((defined $a) && (defined $b))
	       {
	          $ret .= "      gcr $a$b\n" if $i < 5;
		  $sec = "$a$b" if $i == 1;
		  $trk = "$a$b" if $i == 2;
	       }
	       else
	       {
	          $ret .= "      bits $e$f\n" if $i < 5 ;
	       }
	       if ((defined $a) && (defined $b))
	       {
	          $ret .= "   gcr $a$b\n" if $i > 4 ;
	       }
	       else
	       {
	          $ret .= "   bits $e$f\n" if $i > 4 ;
	       }
	       $ret .= "   end-checksum\n" if $i == 4;
	    }
	 }
	 if (defined($trk) && defined($sec))
	 { 
            $ret .= "   ; Trk ".hex($trk)." Sec ".hex($sec)."\n";
	 }
      }
      elsif ($a.$b eq '07')
      {
         $ret .= "   ; data\n";
         $ret .= "   gcr 07\n";

         $ret .= "   begin-checksum\n";
	 my $gcr = "";
         for (my $i=0; $i<259; $i++)
	 {
            my $v3 = $trackPart =~ s/^(.{5})//;
	    unless ($v3)
	    {
	          $ret .= "      gcr$gcr\n" if $gcr;
                  $ret .= ";   block aborted\n";
		  last;	       
	    }
	    my $e = $1;
            my $a = parseGCR($1);
            my $v4 = $trackPart =~ s/^(.{5})//;
	    unless ($v4)
	    {
	          $ret .= "      gcr$gcr\n" if $gcr;
		  $ret .= "   bits $e\n";
                  $ret .= ";   block aborted2\n";
		  last;	       
	    }
	    my $f = $1;
            my $b = parseGCR($1);
	    
	    if ($i < 256)
	    {
	       if ((defined $a) && (defined $b))
	       {
	          $gcr .= " $a$b";
	       }
	       else
	       {
	          $ret .= "      gcr$gcr\n" if $gcr;
	          $ret .= "      bits $e$f\n";
		  $gcr = "";
	       }
	    }
	    elsif ($i == 256)
	    {
	          $ret .= "      gcr$gcr\n" if $gcr;
	          $ret .= "      checksum $a$b\n" if (defined $a) && (defined $b);
	          $ret .= "      checksum $e$f\n" unless (defined $a) && (defined $b);
                  $ret .= "   end-checksum\n";
		  $gcr = "";
	    }
	    else
	    {
	          $ret .= "   gcr $a$b\n" if (defined $a) && (defined $b);
	          $ret .= "   bits $e$f\n" unless (defined $a) && (defined $b);
	    }
	 }

      }
      else
      {
         $ret .= "   gcr $a$b\n" if ((defined $a) && (defined $b));
	 $ret .= "   bits $c$d\n" unless ((defined $a) && (defined $b));
      }
      
      while (length ($trackPart) >= 8)
      {
         $trackPart =~ s/^((.{8})+)//;
         my $trackBin = pack("B*", $1);
	 my $trackContentHex = unpack("H*", $trackBin);
         $trackContentHex =~ s/(..)/ $1/gc;
	 $ret .= "   bytes$trackContentHex\n";

      }
      
      $ret .= "   bits $trackPart\n" if $trackPart ne '';
      
      $track = $trackRest;
      
      $ret .= "\n";
   }
   
   $ret .= "end-track\n\n";
   
   $ret;
}



sub parseGCR
{
   my $x = $_[0];
   
   return '0' if $x eq '01010';
   return '1' if $x eq '01011';
   return '2' if $x eq '10010';
   return '3' if $x eq '10011';
   return '4' if $x eq '01110';
   return '5' if $x eq '01111';
   return '6' if $x eq '10110';
   return '7' if $x eq '10111';
   return '8' if $x eq '01001';
   return '9' if $x eq '11001';
   return 'a' if $x eq '11010';
   return 'b' if $x eq '11011';
   return 'c' if $x eq '01101';
   return 'd' if $x eq '11101';
   return 'e' if $x eq '11110';
   return 'f' if $x eq '10101';
   undef;
}

sub nibbleToGCR
{
   my $x = $_[0];

   return '01010' if $x eq '0';
   return '01011' if $x eq '1';
   return '10010' if $x eq '2';
   return '10011' if $x eq '3';
   return '01110' if $x eq '4';
   return '01111' if $x eq '5';
   return '10110' if $x eq '6';
   return '10111' if $x eq '7';
   return '01001' if $x eq '8';
   return '11001' if $x eq '9';
   return '11010' if $x eq 'a';
   return '11011' if $x eq 'b';
   return '01101' if $x eq 'c';
   return '11101' if $x eq 'd';
   return '11110' if $x eq 'e';
   return '10101' if $x eq 'f';
   undef;
}


sub txttog64
{
   my ($text, $d64) = @_;
   my $file;
   my $line;
   my $tracksizeHdr = 0;
   my $noTracks = 0;
   my @tracks = ();
   my $speed = 4;
   my $beginat;

   open ($file, "<", \$text);
   my $curTrack = "";
   my $curTrackNo = undef;
   
   my $checksumBlock = 0;
   my $checksum = 0;
   
   while ($line = <$file>)
   {
      chomp $line;
      $line =~s/^ +//;
      
      if ($line eq "")
      {
      }
      elsif ($line =~ /^;/)
      {
      }
      elsif ($line =~ /^no-tracks (.*)$/)
      {
         $noTracks = $1;
      }
      elsif ($line =~ /^track-size (.*)$/)
      {
         $tracksizeHdr = $1;
      }
      elsif ($line =~ /^track (.*)$/)
      {
	 $curTrackNo = $1*2-1;
	 $curTrack = "";
	 $beginat = 0;
	 $checksumBlock = 0;
      }
      elsif ($line eq "end-track")
      {
         my $len = length($curTrack);
	 my $trk = ($curTrackNo+1)/2;
	 die "Track $trk length $len bits is not a multilpe of 8 bits\n" if $len % 8;
	 
	 my $tmp = (length($curTrack)-$beginat) % length($curTrack); 
	 my $curTrack2 = substr($curTrack, $tmp) . substr($curTrack, 0, $tmp);
	 
         if ($curTrackNo)
	 {
	    $tracks[$curTrackNo] = [ $speed, $curTrack2 ];
	 }
         $checksumBlock = 0;
      }
      elsif ($line =~ /^speed (.*)$/)
      {
         $speed = $1;
      }
      elsif ($line =~ /^begin-at (.*)$/)
      {
         $beginat = $1;
      }
      elsif ($line =~ /^sync (.*)$/)
      {
         my $par = $1;
	 $curTrack .= 1 x $par;
	 $checksumBlock = 2 if $checksumBlock == 1;
      }
      elsif ($line =~ /^bits (.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
	 $curTrack .= $par;
	 $checksumBlock = 2 if $checksumBlock == 1;
      }
      elsif ($line =~ /^bytes (.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
         my $trackBin = pack("H*", $par);
	 my $trackContentBin = unpack("B*", $trackBin);
	 $curTrack .= $trackContentBin;
	 $checksumBlock = 2 if $checksumBlock == 1;
      }
      elsif ($line eq 'begin-checksum')
      {
         $checksumBlock = 1;
	 $checksum = 0;
      }
      elsif ($line eq 'end-checksum')
      {
         if ($checksumBlock == 1)
	 {
	    my $tmp = unpack("H*", chr($checksum));
	    my $tmp2 = nibbleToGCR( substr($tmp, 0, 1) ) . nibbleToGCR( substr($tmp, 1, 1) );

	    $curTrack =~ s/-{10}/$tmp2/g;
	 }
	 $checksumBlock = 0;
      }
      elsif ($line =~ /^gcr (.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
	 
	 for my $i (split //, $par)
	 {
	    $curTrack .= nibbleToGCR($i);
	 }
	 
	 if ($checksumBlock == 1)
	 {
            my $tmp = pack("H*", $par);
	    my @tmp = unpack("C*", $tmp);
	    for my $i (@tmp)
	    {
	       $checksum ^= $i;
	    }
	 }
      }
      elsif ($line =~ /^extgcr (.*) (.*)$/ && defined $d64)
      {
         my $pos = hex($1);
	 my $size = hex($2);
	 
         my $par = unpack("H*", substr($d64, $pos, $size));
	 
	 for my $i (split //, $par)
	 {
	    $curTrack .= nibbleToGCR($i);
	 }
	 
	 if ($checksumBlock == 1)
	 {
            my $tmp = pack("H*", $par);
	    my @tmp = unpack("C*", $tmp);
	    for my $i (@tmp)
	    {
	       $checksum ^= $i;
	    }
	 }
      }
      elsif ($line =~ /^checksum(.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
	 
	 if (length($par) == 10)
	 {
            $curTrack .= $par;
	 }
	 elsif ($par ne '')
	 {
	    for my $i (split //, $par)
	    {
	       $curTrack .= nibbleToGCR($i);
	    }
	 }
	 else
	 {
	    $curTrack .= "-" x 10;
	 }
      }
      else
      {
         die "Unknown line: $line\n";
      }
   }
   close $file;
   
   my $g64 = "GCR-1541\0" . pack("C", $noTracks) . pack("S", $tracksizeHdr);
   $g64 .= "\0\0\0\0" x $noTracks;
   $g64 .= "\0\0\0\0" x $noTracks;
   
   for (my $i=1; $i<$noTracks; $i++)
   {
      next unless defined $tracks[$i];
      my $trackSpeed = $tracks[$i]->[0]-0;
      my $trackContent = $tracks[$i]->[1];
      
      my $track2 = ($i+1)/2;
      my $trackTablePosition = 8+4*$i;
      my $speedTableOffset = 8+4*$noTracks + 4*$i;
      
      my $tmp = pack("L", length($g64));
      substr($g64, $trackTablePosition, 4) = $tmp;
      substr($g64, $speedTableOffset, 4) = pack("L", $trackSpeed);
      
      my $tmp = pack("B*", $trackContent);
      my $siz = length($tmp);
      my $tmpSize = pack("S", $siz);
      $g64 .= $tmpSize.$tmp.("\0" x ($tracksizeHdr-$siz));
   }
   
   $g64;
}

sub stddisk
{
   my $ret = "no-tracks 84\ntrack-size 7928\n";
   my $i;
   my $o = 0;
   for ($i=1; $i<36; $i++)
   {
      my $s = 21;
      $s = 19 if $i >= 18;
      $s = 18 if $i >= 25;
      $s = 17 if $i >= 31;
      
      $ret .= "track $i\n";
      $ret .= "   speed 3\n" if $s == 21;
      $ret .= "   speed 2\n" if $s == 19;
      $ret .= "   speed 1\n" if $s == 18;
      $ret .= "   speed 0\n" if $s == 17;
      $ret .= "   begin-at 0\n";
      
      my $j;
      for ($j = 0; $j < $s; $j++)
      {
         $ret .="   sync 32\n   gcr 08\n"
	       ."   begin-checksum\n      checksum\n"
	       ."      gcr ".sprintf("%02x", $j)."\n"      
	       ."      gcr ".sprintf("%02x", $i)."\n"
	       ."      extgcr 165a3 1\n"
	       ."      extgcr 165a2 1\n"
	       ."   end-checksum\n"
	       ."   gcr 0f\n"
	       ."   gcr 0f\n"
	       ."   bytes 55 55 55 55 55 55 55 55 55 ff\n"
	       ."\n"
	       ."   sync 32\n   gcr 07\n"
	       ."   begin-checksum\n"
	       ."      extgcr ".sprintf("%2x", $o)." 100\n"
	       ."      checksum\n"
	       ."   end-checksum\n"
	       ."   gcr 00\n"
	       ."   gcr 00\n"
	       ."   bytes 55 55 55 55 55 55 55 55 ff\n";
	       
         $o += 256;
      }
      $ret .="end-track\n\n";
   }
   $ret;
}
