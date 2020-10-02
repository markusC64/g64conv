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
#perl2exe_include "PerlIO.pm"
#perl2exe_include "File/Glob.pm"

use strict;

if (@ARGV < 2)
{
   die "Syntax: g64conv.pl <from.g64> <to.txt> [mode]\n".
       "        g64conv.pl <from.txt> <to.g64>\n".
       "        g64conv.pl <from.d64> <to.g64>\n".
       "        g64conv.pl <from.d71> <to.g64>\n".
       "        g64conv.pl <from.reu> <to.g64>\n".
       "        g64conv.pl <from.g64> <to.reu> [reduceSync]\n".
       "        g64conv.pl <fromTemplate.txt> <to.g64> <from.d64>\n".
       "        g64conv.pl <fromTemplate.txt> <to.g64> <from.d71>\n".

       "        g64conv.pl <from??.0.raw.raw> <to.txt> <fluxMode> <rotation>\n".
       "        g64conv.pl <from??.0.raw.raw> <to.g64> <rotation>\n".
       "        g64conv.pl <from.txt> <to.txt>\n <mode|fluxMode>\n".

       "        g64conv.pl <from.nb2> <to.txt> [mode]\n".

       "        g64conv.pl <from.g71> <to.txt> [mode]\n".
       "        g64conv.pl <from.txt> <to.g71>\n".
       "        g64conv.pl <from.d64> <to.g71>\n".
       "        g64conv.pl <from.d71> <to.g81>\n".
       "        g64conv.pl <fromTemplate.txt> <to.g71> <from.d64>\n".
       "        g64conv.pl <fromTemplate.txt> <to.g71> <from.d71>\n".

       "        g64conv.pl filter <from.txt> <to.txt> <range> <offset>\n".

       "mode may be 0 (hex only) or 1 (gcr parsed, default) or\n".
       "        2 (gcr parsed with warp25 heuristic).\n".
       "        3 (gcr parsed, max 16 bytes per line).\n".
       "        5 (gcr parsed, with raw bytes comment).\n".
       "        6 (gcr parsed, max 16 bytes per line, with raw bytes comment).\n".
       "        or p64 for p64 compatible flux position list\n".
       "fluxMode can be any value of mode and raw or rawUnpadded.\n".
       "reduceSync may be 0 (disabled) or 1 (enabled, default).\n";
}


my $from = $ARGV[0];
my $to = $ARGV[1];
my $level = $ARGV[2];
my $pass = $ARGV[3];

my %warp25tableEnc = ( 0 => 73, 1 => 74, 2 => 75, 3 => 77, 4 => 78, 5 => 82, 6 => 83, 7 => 85, 8 => 86, 9 => 89, 10 => 90, 11 => 91, 12 => 93, 13 => 94, 14 => 101, 15 => 102, 32 => 105, 33 => 106, 34 => 107, 35 => 109, 36 => 110, 37 => 114, 38 => 115, 39 => 117, 40 => 118, 41 => 121, 42 => 122, 43 => 123, 44 => 146, 45 => 147, 46 => 149, 47 => 150, 64 => 153, 65 => 154, 66 => 155, 67 => 157, 68 => 158, 69 => 165, 70 => 166, 71 => 169, 72 => 170, 73 => 171, 74 => 173, 75 => 174, 76 => 178, 77 => 179, 78 => 181, 79 => 182, 96 => 185, 97 => 186, 98 => 187, 99 => 189, 100 => 201, 101 => 202, 102 => 203, 103 => 205, 104 => 206, 105 => 210, 106 => 211, 107 => 213, 108 => 214, 109 => 217, 110 => 218, 111 => 219,  );
my %warp25tableDec = ();
for my $i (keys %warp25tableEnc)
{
   $warp25tableDec{$warp25tableEnc{$i}} = $i;
}



if ($from =~ /\.g((64)|(71))$/i && $to =~ /\.txt$/i)
{
   $level = 1 unless defined $level;
   my $g64 = readfileRaw($from);
   my $txt;
   $txt = g64top64txt($g64) if $level eq "p64";
   $txt = g64totxt($g64, $level) unless $level eq "p64";
   writefile($txt, $to);
}
elsif ($from =~ /\.g64$/i && $to =~ /\.g64$/i)
{
   my $g64 = readfileRaw($from);
   my $txt;
   $txt = g64totxt($g64, 0);
   $g64 = txttog64($txt, undef, "1541");
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.g71$/i && $to =~ /\.g71$/i)
{
   my $g64 = readfileRaw($from);
   my $txt;
   $txt = g64totxt($g64, 0);
   $g64 = txttog64($txt, undef, "1571");
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.d64$/i && $to =~ /\.g64$/i)
{
   my $txt = stddisk();
   my $d64 = readfileRaw($from);
   my $g64 = txttog64($txt, $d64, "1541");
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.d64$/i && $to =~ /\.g71$/i)
{
   my $txt = stddisk();
   my $d64 = readfileRaw($from);
   my $g64 = txttog64($txt, $d64, "1571");
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.reu$/i && $to =~ /\.g64$/i)
{
   my $reu = readfileRaw($from);
   my $g64 = reutog64($reu);
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.g64$/i && $to =~ /\.reu$/i)
{
   $level = 1 unless defined $level;
   my $reu = readfileRaw($from);
   my $g64 = g64toreu($reu, $level);
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.d71$/i && $to =~ /\.g64$/i)
{
   my $txt = stddisk1571();
   my $d64 = readfileRaw($from);
   my $g64 = txttog64($txt, $d64, "1541");
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.d71$/i && $to =~ /\.g71$/i)
{
   my $txt = stddisk1571();
   my $d64 = readfileRaw($from);
   my $g64 = txttog64($txt, $d64, "1571");
   writefileRaw($g64, $to);
}
elsif ($from =~ /\.txt$/i && $to =~ /\.g((64)|(71))$/i)
{
   my $dest = "1541";
   $dest = "1571" if $to =~ /\.g71$/i;

   my $txt = readfile($from);
   if ($txt =~ /^\s+flux/mi)
   {
       my $p64 = parseP64txt($txt);
       
       my $ret0 .= "";
       my $ret1 = "";
       
       my $tracks = $p64->{tracks};

      foreach my $trackData (@$tracks)
      {
         my $trackNoRaw = $trackData->{track};
        my $trackNo = $trackNoRaw;
         my $side = 0;
      	 if ($trackNo > 127.75)
      	 {
      	    $trackNo -= 128;
      	    $side = 1;
      	 }
         
        my $Flux = normalizeP64Flux ($trackData->{flux});

         my $speed = getSpeedZone1($Flux, $trackNo);
         my $bitstream = fluxtobitstream($Flux, $speed);
         $bitstream = padbitstream($bitstream);
        
            if ($side == 0)
            {
               $ret0 .= "track $trackNo\n";
               $ret0 .= "   speed $speed\n";
               $ret0 .= "   bits $bitstream\n";
               $ret0 .= "end-track\n";
            }
            else
            {
               $trackNo += 42;
               $ret1 .= "track $trackNo\n";
               $ret1 .= "   speed $speed\n";
               $ret1 .= "   bits $bitstream\n";
               $ret1 .= "end-track\n";
            }
      
      }
     
       my $ret = "no-tracks 84\ntrack-size 7928\n" unless $ret1;
       $ret = "no-tracks 168\ntrack-size 7928\n" if $ret1;
       my $gxx = txttog64($ret.$ret0.$ret1, undef,  $dest);
       writefileRaw($gxx, $to);
   }
   else
   {
      my $d64 = undef;
      $d64 = readfileRaw($level) if defined $level;
      my $g64 = txttog64($txt, $d64, $dest);
      writefileRaw($g64, $to);
   }
}
elsif ($from =~ /\.g((64)|(71))$/i && $to =~ /\.d64$/i)
{
   my $g64 = readfileRaw($from);
   my $d64 = g64tod64($g64);
   writefileRaw($d64, $to);
}
elsif ($from =~ /\.g((64)|(71))$/i && $to =~ /\.d71$/i)
{
   my $g64 = readfileRaw($from);
   my $d71 = g64tod71($g64);
   writefileRaw($d71, $to);
}
elsif ($from =~ /\.nb2$/i && $to =~ /\.txt$/i)
{
   my $nb2 = readfileRaw($from);
   my $txt = nb2totxt($nb2, $level // 1, $pass // 0);
   writefile($txt, $to);
}
elsif ($from =~ /\\?\?\.[01]\.raw$/i && $to =~ /\.txt$/i)
{
   $level = 1 unless defined $level;
   $pass = 0 unless defined $pass;

  my @src = sort glob $from;
  
  my $ret = "";
  $ret .= "no-tracks 84\ntrack-size 7928\n"  if $level ne "p64";

  for my $filename (@src)
  {
     $filename =~ /(..)\.([01])\.raw$/i;
     my ($rawtrack, $side) = ($1, $2);
     my $trackNo = $rawtrack/2+1;
     
     ## next if $rawtrack % 2 == 1;
     
     print "Parsiing $filename\n";

     my $track = readfileRaw($filename);
     my $fluxRaw = parseKryofluxRawFile($track);
     my $fluxMetadata = extractRotation($fluxRaw, $pass);
     my $Flux = kryofluxNormalize($fluxRaw, $fluxMetadata);
     $Flux = reverseFlux($Flux) if $side == 1;

     if ($level eq "p64")
     {
        $ret .= "track $trackNo\n";
        my $sum = 1;
        for my $v (@$Flux)
        {
           my $y = $v * 3200000 ;
           $sum += $y;
           $sum -= 3200000 if $sum >= 3200000;
           $ret .= "   flux $sum\n";
        }
     }
     else
     {
        my $speed = getSpeedZone1($Flux, $trackNo);
        my $bitstream = fluxtobitstream($Flux, $speed);
        $bitstream = padbitstream($bitstream) unless $level eq "rawUnpadded";
        
        $ret .= "track $trackNo\n";
        $ret .= "   speed $speed\n";
        $ret .= "   bits $bitstream\n";
        $ret .= "end-track\n";
     }
  }
        if ($level ne "raw" && $level ne "rawUnpadded" && $level ne "p64")
        {
             my $g64 = txttog64($ret, undef, "1541");
             $ret = g64totxt($g64, $level)
        }
    
  writefile($ret, $to);
}
elsif ($from =~ /\\?\?\.[01]\.raw$/i && $to =~ /\.g64$/i)
{
   $level = "0" unless defined $level;

  my @src = sort glob $from;
  
  my $ret .= "no-tracks 84\ntrack-size 7928\n";

  for my $filename (@src)
  {
     $filename =~ /(..)\.([01])\.raw$/i;
     my ($rawtrack, $side) = ($1, $2);
     my $trackNo = $rawtrack/2+1;
     
     ## next if $rawtrack % 2 == 1;
     
     print "Parsiing $filename\n";

     my $track = readfileRaw($filename);
     my $fluxRaw = parseKryofluxRawFile($track);
     my $fluxMetadata = extractRotation($fluxRaw, $level);
     my $Flux = kryofluxNormalize($fluxRaw, $fluxMetadata);
     $Flux = reverseFlux($Flux) if $side == 1;

     my $speed = getSpeedZone1($Flux, $trackNo);
     my $bitstream = fluxtobitstream($Flux, $speed);
     $bitstream = padbitstream($bitstream);
    
     $ret .= "track $trackNo\n";
     $ret .= "   speed $speed\n";
     $ret .= "   bits $bitstream\n";
     $ret .= "end-track\n";
  }
  
  my $g64 = txttog64($ret, undef, "1541");
  writefileRaw($g64, $to);
}




elsif ($from =~ /\\?\?\.\?\.raw$/i && $to =~ /\.txt$/i)
{
   $level = 1 unless defined $level;
   $pass = 0 unless defined $pass;

  my @src = sort glob $from;
  
  my $ret0 = "";
  my $ret1 = "";
  $ret0 .= "no-tracks 168\ntrack-size 7928\n"  if $level ne "p64";
  $ret0 = "sides 2\n" if $level eq "p64";

  for my $filename (@src)
  {
     $filename =~ /(..)\.([01])\.raw$/i;
     my ($rawtrack, $side) = ($1, $2);
     my $trackNo = $rawtrack/2+1;
     
     ## next if $rawtrack % 2 == 1;
     
     print "Parsiing $filename\n";

     my $track = readfileRaw($filename);
     my $fluxRaw = parseKryofluxRawFile($track);
     my $fluxMetadata = extractRotation($fluxRaw, $pass);
     my $Flux = kryofluxNormalize($fluxRaw, $fluxMetadata);

     if ($level eq "p64")
     {
     	$trackNo += 128 if $side == 1;
        $ret0 .= "track $trackNo\n" if $side == 0;
        $ret1 .= "track $trackNo\n" if $side == 1;
        my $sum = 1;
        for my $v (@$Flux)
        {
           my $y = $v * 3200000;
           $sum += $y;
           $sum -= 3200000 if $sum >= 3200000;
           $ret0 .= "   flux $sum\n" if $side == 0;
           $ret1 .= "   flux $sum\n" if $side == 1;
        }
     }
     else
     {
        my $speed = getSpeedZone1($Flux, $trackNo);
        my $bitstream = fluxtobitstream($Flux, $speed);
        $bitstream = padbitstream($bitstream) unless $level eq "rawUnpadded";
        
        if ($side == 0)
        {
           $ret0 .= "track $trackNo\n";
           $ret0 .= "   speed $speed\n";
           $ret0 .= "   bits $bitstream\n";
           $ret0 .= "end-track\n";
        }
        else
        {
           $trackNo += 42;
           $ret1 .= "track $trackNo\n";
           $ret1 .= "   speed $speed\n";
           $ret1 .= "   bits $bitstream\n";
           $ret1 .= "end-track\n";
        }
     }
  }
  
  my $ret = $ret0.$ret1;
        if ($level ne "raw" && $level ne "rawUnpadded" && $level ne "p64")
        {
             my $g64 = txttog64($ret, undef, "1541");
             $ret = g64totxt($g64, $level)
        }
  writefile($ret, $to);
}
elsif ($from =~ /\\?\?\.\?\.raw$/i && $to =~ /\.g((64)|(71))$/i)
{
   my $dest = "1541";
   $dest = "1571" if $to =~ /\.g71$/i;
	
   $level = "0" unless defined $level;

  my @src = sort glob $from;
  
  my $ret0 .= "no-tracks 168\ntrack-size 7928\n";
  my $ret1 = "";

  for my $filename (@src)
  {
     $filename =~ /(..)\.([01])\.raw$/i;
     my ($rawtrack, $side) = ($1, $2);
     my $trackNo = $rawtrack/2+1;
     
     ## next if $rawtrack % 2 == 1;
     
     print "Parsiing $filename\n";

     my $track = readfileRaw($filename);
     my $fluxRaw = parseKryofluxRawFile($track);
     my $fluxMetadata = extractRotation($fluxRaw, $level);
     my $Flux = kryofluxNormalize($fluxRaw, $fluxMetadata);
     $Flux = reverseFlux($Flux) if $side == 1;

     my $speed = getSpeedZone1($Flux, $trackNo);
     my $bitstream = fluxtobitstream($Flux, $speed);
     $bitstream = padbitstream($bitstream);
    
        if ($side == 0)
        {
           $ret0 .= "track $trackNo\n";
           $ret0 .= "   speed $speed\n";
           $ret0 .= "   bits $bitstream\n";
           $ret0 .= "end-track\n";
        }
        else
        {
           $trackNo += 42;
           $ret1 .= "track $trackNo\n";
           $ret1 .= "   speed $speed\n";
           $ret1 .= "   bits $bitstream\n";
           $ret1 .= "end-track\n";
        }
  }
  
  my $gxx = txttog64($ret0.$ret1, undef,  $dest);
  writefileRaw($gxx, $to);
}

elsif ($from =~ /\.txt$/i && $to =~ /\.txt$/i)
{
   $level = 1 unless defined $level;
   my $txt = readfile($from);
   if ($txt =~ /^\s+flux/mi)
   {
       my $p64 = parseP64txt($txt);
       
       my $ret0 .= "";
       my $ret1 = "";
       
       my $tracks = $p64->{tracks};

      foreach my $trackData (@$tracks)
      {
         my $trackNoRaw = $trackData->{track};
        my $trackNo = $trackNoRaw;
         my $side = 0;
      	 if ($trackNo > 127.75)
      	 {
      	    $trackNo -= 128;
      	    $side = 1;
      	 }
         
        my $Flux = normalizeP64Flux ($trackData->{flux});

         my $speed = getSpeedZone1($Flux, $trackNo);
         my $bitstream = fluxtobitstream($Flux, $speed);
         $bitstream = padbitstream($bitstream) unless $level eq "rawUnpadded";
        
            if ($side == 0)
            {
               $ret0 .= "track $trackNo\n";
               $ret0 .= "   speed $speed\n";
               $ret0 .= "   bits $bitstream\n";
               $ret0 .= "end-track\n";
            }
            else
            {
               $trackNo += 42;
               $ret1 .= "track $trackNo\n";
               $ret1 .= "   speed $speed\n";
               $ret1 .= "   bits $bitstream\n";
               $ret1 .= "end-track\n";
            }
      
      }
     
       my $ret = "no-tracks 84\ntrack-size 7928\n" unless $ret1;
       $ret .= "no-tracks 168\ntrack-size 7928\n" if $ret1;
       
       if ($level ne "raw" && $level ne "rawUnpadded")
       {
         my $gxx = txttog64($ret.$ret0.$ret1, undef,  "1541");
         $txt = g64totxt($gxx, $level);
       }
       else
       {
          $txt = $ret.$ret0.$ret1;
       }
      writefile($txt, $to);
   }
   else
   {
      $level = 1 unless defined $level;
      my $g64 = txttog64($txt, undef, "1541");
      my $txt;
      $txt = g64top64txt($g64) if $level eq "p64";
      $txt = g64totxt($g64, $level) unless $level eq "p64";
      writefile($txt, $to);
   }
}
elsif ($from eq "filter" &&  $to =~ /\.txt$/i)
{
   my $print = 1;

   my $range = $pass;
   $range = "1..35,43..77,129..163" unless defined $range;
   my $ret = "";
   my $range2 = parseRange($range);
   
   my $offset = $ARGV[5];
   $offset = "0" unless defined $offset;
   
   open (my $file, "<", $to);

   while (<$file>)
   {
      chomp;
      if ( /^\s*track (.+)$/ )
      {
      	 my $tr = $1;
         $print = 1;
         $print = 0 unless exists $range2->{$tr};
         $ret .= "track " . ($tr+$offset) . "\n"if $print;
         next;
      }
      $ret .=  "$_\n" if $print;
   }

   writefile($ret, $level);
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
   return undef unless ($signature eq 'GCR-1541' || $signature eq 'GCR-1571');

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
      if ($speed > 4)
      {
         my $tmp = substr($g64, $speed, $tracksizeHdr/4);
	 my $tmp2 = unpack("B*", $tmp);
	 $speed = "";
	 while (length($speed) < 8*$trackSize)
	 {
	    if ($tmp2 =~ s/^00//)
	    {
	       $speed .= "0" x 8;
	    }
	    elsif ($tmp2 =~ s/^01//)
	    {
	       $speed .= "1" x 8;
	    }
	    elsif ($tmp2 =~ s/^10//)
	    {
	       $speed .= "2" x 8;
	    }
	    elsif ($tmp2 =~ s/^11//)
	    {
	       $speed .= "3" x 8;
	    }
	 }
      }
      
      my $trackRet = "track $track\n";
      if ($level == 0)
      {
         $trackRet .= "   ; length $trackSize\n";
         $trackRet .= "   speed $speed\n   bytes$trackContentHex\n";
	 $trackRet .= "end-track\n\n";
      }
      else
      {
         my $tmp = $trackContentHex;
	 $tmp =~ s/ //g;
         my $trackBin = pack("H*", $tmp);
	 my $trackContentBin = unpack("B*", $trackBin);
	 
         $tmp = parseTrack($trackContentBin, $speed, $level, 1);
	 unless (defined $tmp)
	 {
            $tmp =  "   speed $speed\n";
	    $tmp .= "   begin-at 0\n   bytes$trackContentHex\n";
	    $tmp .= "end-track\n\n";
	 }
	 
         $trackRet .= "   ; length $trackSize\n";
	 $trackRet .= $tmp;
      }
      
      $ret .= $trackRet;
   }
   
   
   $ret;
}

sub parseTrack
{
   my $track = $_[0];
   my $speed = $_[1];
   my $mode = $_[2];
   my $normalize = $_[3];
   
   my $ret;
   my $beginat;
   my $curspeed;
   
   if ($normalize)
   {
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
   
      
      my $revTrack = reverse $track;
      if ($revTrack =~m/^(1+)(1{9})(.*)$/)
      {
         my $offset = length($1);
         $track = reverse "$2$3$1";
         $beginat -= $offset;
         $beginat += length($track) if $beginat < 0;
      }
   }
      
   if (length($speed) > 1)
   {
      $speed = substr($speed, $beginat) . substr($speed, 0, $beginat);
      $curspeed = substr($speed, 0, 1);
      $ret  = "   speed $curspeed\n";
   }
   else
   {
      $ret  = "   speed $speed\n";
      $curspeed = $speed;
      $speed = $speed x length($track);
   }

   $ret .= "   begin-at $beginat\n";
   
   my $trackPos = 0;

   while ($track ne "")
   {
      # Remark: No need to test for > 9 bits cause we arranged that $track is starting with sync
      # which is continued from last "trackPart"!
      if ($curspeed ne substr($speed, $trackPos, 1))
      {
         $curspeed = substr($speed, $trackPos, 1);
         $ret .= "   speed $curspeed\n";
      }
      $track =~ s/^(1+)//;
      $ret .= "   sync " . length($1) . "\n";
      $trackPos += length($1);

      if ($track ne "" && $curspeed ne substr($speed, $trackPos, 1))
      {
         $curspeed = substr($speed, $trackPos, 1);
         $ret .= "   speed $curspeed\n";
      }

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
      
      if ($mode == 5 || $mode == 6)
      {
         my $trackPart2 = $trackPart;
         while (length ($trackPart2) >= 8)
         {
            $trackPart2 =~ s/^((.{8})+)//;
            my $trackBin = pack("B*", $1);
	    my $trackContentHex = unpack("H*", $trackBin);
            $trackContentHex =~ s/(..)/ $1/gc;
	    $ret .= "   ; Following raw bytes: $trackContentHex\n";
         }
      
         $ret .= "   ; Following raw bits: $trackPart2\n" if $trackPart2 ne '';
      }
      
      my $v1 = $trackPart =~ s/^(.{5})//;
      my $c = $1;
      unless ($v1)
      {
         $c = $trackPart;
	 $trackPart = "";
      }
      $trackPos += length($c);
      if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
      {
         $curspeed = substr($speed, $trackPos, 1);
         $ret .= "   speed2 $curspeed\n";
      }
      my $a = parseGCR($c);
      my $v2 = $trackPart =~ s/^(.{5})//;
      my $d = $1;
      unless ($v2)
      {
         $d = $trackPart;
	 $trackPart = "";
      }
      $trackPos += length($d);
      my $b = parseGCR($d);

      if ($a.$b eq '08')
      {
         $ret .= "   ; header\n";
         $ret .= "   gcr 08\n";
	 
	 my $trk = undef;
	 my $sec = undef;
	 
         my $checksum = 0;
         my $checksumImage = 0;
         my $checksumInvalid = 0;

         for (my $i=0; $i<7; $i++)
	 {
            if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed $curspeed\n";
            }
            my $v3 = $trackPart =~ s/^(.{5})//;
	    unless ($v3)
	    {
                  $ret =~ s/&&&&\n//sg;
                  $ret .= ";   block aborted\n";
		  last;	       
	    }
	    my $e = $1;
            $trackPos += length($e);
            if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed2 $curspeed\n";
            }
            my $a = parseGCR($1);
            my $v4 = $trackPart =~ s/^(.{5})//;
	    unless ($v4)
	    {
                  $ret =~ s/&&&&\n//sg;
		  $ret .= "   bits $e\n";
                  $ret .= ";   block aborted\n";
		  last;	       
	    }
	    my $f = $1;
            $trackPos += length($f);
            my $b = parseGCR($1);
	    
	    if ($i == 0)
	    {
	       $ret .= "   begin-checksum\n";
	       $ret .= "&&&&\n";
	       $ret .= "      checksum $a$b\n" if (defined $a) && (defined $b);
	       $ret .= "      checksum $e$f\n" unless (defined $a) && (defined $b);
	       $checksum = hex("$a$b") if (defined $a) && (defined $b);
	       $checksumImage = $checksum;
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
		  $checksum ^= hex("$a$b") if $i < 5;
		  $sec = "$a$b" if $i == 1;
		  $trk = "$a$b" if $i == 2;
	       }
	       else
	       {
	          $ret .= "      bits $e$f\n" if $i < 5 ;
	          $checksumInvalid = 1;
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
	       $ret .= "   ; invalid checksum\n" if $checksum && $i == 4;
	       if ($i == 4)
	       {
                   if ($checksum && !$checksumInvalid)
                   {
                   	my $corChecksum = $checksum ^ $checksumImage;
                   	my $corChecksumHex = sprintf "%02x", $corChecksum;
                   	$ret =~ s/&&&&/      ; checksum wrong, should be $corChecksumHex/g;
                   }
                   else
                   {
                   	## $ret =~ s/&&&&/      ; checksum ok/g;
                   	$ret =~ s/&&&&\n//sg;
                   }
	       }
	    }
	 }
	 if (defined($trk) && defined($sec))
	 { 
            $ret .= "   ; Trk ".hex($trk)." Sec ".hex($sec)."\n";
	 }
      }
      elsif ($a.$b eq "07" && substr($trackPart, 0, 14) eq "01010010101101" && $mode == 2)
      {
         $ret .= "   ; warp 25 data\n";
         $ret .= "   gcr 07\n";

           if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed2 $curspeed\n";
            }
          
         $ret .= "   bits ".substr($trackPart, 0, 6)."\n";
	 $trackPart =~ s/^......//;
	 $speed =~ s/^......//;

           if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed2 $curspeed\n";
            }

	 $ret .= "   bytes ad\n";
	 $trackPart =~ s/^........//;
	 $speed =~ s/^........//;

	 $ret .= "   begin-checksum\n";
         # Decode 320 Bytes (Warp 25)
	 
	 my $w25 = "";
	 my $warp = 0;
	 
         for (my $i=0; $i<321; $i++)
	 {
            if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
	       $ret .= "      warp25-raw$w25\n" if $w25;
	       $w25 = "";
               $warp = 0;
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed $curspeed\n";
            }
	    
	    #$speed =~ s/^(.{8})//;
            my $avail = $trackPart =~ s/^(.{8})//;
	    
            my $byteChr = pack("B*", $1);
	    my $byte = ord($byteChr);
	    my $byteHex = unpack("H*", $byteChr);
	    my $newwarp = $warp25tableDec{$byte};
	    my $warpByte = undef;
	    if (defined $warp)
	    {
	       $warp ^= $newwarp;
	       $warpByte = unpack("H*", chr($warp));
	    }
	   

	    if ($i < 320)
	    {
	       if ((defined $warpByte))
	       {
	          $w25 .= " $warpByte";
	       }
	       else
	       {
	          $ret .= "      warp25-raw$w25\n" if $w25;
	          $ret .= "      bytes $byteHex\n";
		  $w25 = "";
                  $warp = 0;
	       }
	    }
	    else
	    {
                  if (length($w25) == 960)
		  {
		     my $tmp = $w25;
		     $w25 = "";
		     $tmp =~ s/ //g;
		     my $sektor = pack("H*", $tmp);
		     $tmp = "";
		     for (my $i=0; $i<320; $i++)
		     {
		        my $val = ord(substr($sektor, $i, 1));
			
			$tmp .= ($val & 8) ? '1':'0';  
			$tmp .= ($val & 2) ? '1':'0';  
			$tmp .= ($val & 64) ? '1':'0';  
			$tmp .= ($val & 4) ? '1':'0';  
			$tmp .= ($val & 32) ? '1':'0';  
			$tmp .= ($val & 1) ? '1':'0';
		     }
		     $tmp = unpack("H*", pack("b*", $tmp));
		     $tmp =~ s/(..)/ $1/gc;

		     $ret .= "      warp25$tmp\n";
		  }
	          $warpByte = undef;
	          if (defined $newwarp)
	          {
	             $warpByte = unpack("H*", chr($newwarp));
	          }
	          $ret .= "      warp25-raw$w25\n" if $w25;
	          $ret .= "      warp25-checksum $warpByte\n" if defined $warpByte;
	          $ret .= "      bytes $byteHex\n" unless defined $warpByte;
                  $ret .= "   end-checksum\n";
		  $ret .= "   ; invalid checksum\n" if $warp;
		  $w25 = "";
	    }
	 }
	 

      }


      elsif ($a.$b eq '07')
      {
         $ret .= "   ; data\n";
         $ret .= "   gcr 07\n";

         $ret .= "   begin-checksum\n";

         my $checksum = 0;
         my $checksumImage = 0;
         my $checksumInvalid = 0;

	 my $gcr = "";
         for (my $i=0; $i<259; $i++)
	 {
            if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
	       $ret .= "      gcr$gcr\n" if $gcr;
	       $gcr = "";
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed $curspeed\n";
            }
            my $v3 = $trackPart =~ s/^(.{5})//;
	    unless ($v3)
	    {
	          $ret .= "      gcr$gcr\n" if $gcr;
                  $ret .= ";   block aborted\n";
		  last;	       
	    }
	    my $e = $1;
            my $a = parseGCR($1);
	    $trackPos += 5;

            if ($trackPart ne "" && $curspeed ne substr($speed, $trackPos, 1))
            {
	       $ret .= "      gcr$gcr\n" if $gcr;
	       $gcr = "";
               $curspeed = substr($speed, $trackPos, 1);
               $ret .= "   speed2 $curspeed\n";
            }
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
	    $trackPos += 5;
	    
	    if ($i < 256)
	    {
	       if ((defined $a) && (defined $b))
	       {
	          $gcr .= " $a$b";
		  $checksum ^= hex("$a$b");
		  
		  if (($i % 16 == 15) && ($mode == 3 || $mode == 6))
		  {
	             $ret .= "      gcr$gcr\n" if $gcr;
		     $gcr = "";
		  }
	       }
	       else
	       {
	       	  $checksumInvalid = 1;
	       	
	          $ret .= "      gcr$gcr\n" if $gcr;
	          $ret .= "      bits $e$f\n";
		  $gcr = "";
	       }
	    }
	    elsif ($i == 256)
	    {
	          $ret .= "      gcr$gcr\n" if $gcr;

		  $checksum ^= hex("$a$b") if (defined $a) && (defined $b);
		  $checksumImage = hex("$a$b") if (defined $a) && (defined $b);

                  if ($checksum && !$checksumInvalid)
                  {
                  	my $corChecksum = $checksum ^ $checksumImage;
                   	my $corChecksumHex = sprintf "%02x", $corChecksum;
                   	$ret .= "      ; checksum wrong, should be $corChecksumHex\n";
                  }

	          $ret .= "      checksum $a$b\n" if (defined $a) && (defined $b);
	          $ret .= "      checksum $e$f\n" unless (defined $a) && (defined $b);
                  $ret .= "   end-checksum\n";
		  $ret .= "   ; invalid checksum\n" if $checksum;
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
      
      my @trackParts = ();
      my $speedsPart = substr($speed, $trackPos, length($trackPart));
      my $tmp = $trackPart; 
      while ($tmp ne "")
      {
         my $speed1 = substr($speedsPart, 0, 1);
	 $speedsPart =~ s/^($speed1+)//;
	 my $len = length($1);
	 push (@trackParts, substr($tmp, 0, $len));
	 $tmp = substr($tmp, $len);
      }
      
      for my $trackPart2 (@trackParts)
      {
         if ($trackPart2 ne "" && $curspeed ne substr($speed, $trackPos, 1))
         {
            $curspeed = substr($speed, $trackPos, 1);
            $ret .= "   speed $curspeed\n";
         }
      
         while (length ($trackPart2) >= 8)
         {
            $trackPart2 =~ s/^((.{8})+)//;
	    $trackPos += length($1);
            my $trackBin = pack("B*", $1);
	    my $trackContentHex = unpack("H*", $trackBin);
            $trackContentHex =~ s/(..)/ $1/gc;
	    $ret .= "   bytes$trackContentHex\n";

         }
      
         $ret .= "   bits $trackPart2\n" if $trackPart2 ne '';
         $trackPos += length($trackPart2);
      }
      
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
   my ($text, $d64, $format) = @_;
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
	 if (length($speed) > 1)
	 {
            my $curSpeed = substr($speed, -1, 1);
	    my $len = $len - length($speed);
	    $speed .= $curSpeed x $len;
         }
	 my $trk = ($curTrackNo+1)/2;
	 die "Track $trk length $len bits is not a multilpe of 8 bits\n" if $len % 8;
	 
	 my $tmp = (length($curTrack)-$beginat) % length($curTrack); 
	 my $curTrack2 = substr($curTrack, $tmp) . substr($curTrack, 0, $tmp);
	 my $speed2 = substr($speed, $tmp) . substr($speed, 0, $tmp);
	 
         if ($curTrackNo)
	 {
	    $tracks[$curTrackNo] = [ $speed, $curTrack2 ];
	 }
         $checksumBlock = 0;
	 $speed = 4;
      }
      elsif ($line =~ /^speed (.*)$/)
      {
         if ($speed eq "4")
	 {
            $speed = $1;
	 }
	 else
	 {
	    my $newSpeed = $1;
	    my $curSpeed = substr($speed, -1, 1);
	    my $len1 = length($curTrack);
	    my $len2 = $len1 + $beginat;
	    $len2 = $len2 - $len1 % 8;
	    $len2 -= $beginat;
	    my $len = $len2 - length($speed);
	    $speed .= $curSpeed x $len;
	    $speed .= $newSpeed;
	 }
      }
      elsif ($line =~ /^speed2 (.*)$/)
      {
         if ($speed eq "4")
	 {
            $speed = $1;
	 }
	 else
	 {
	    my $newSpeed = $1;
	    my $curSpeed = substr($speed, -1, 1);
	    my $len1 = length($curTrack);
	    my $len2 = $len1 - 5 + $beginat;
	    $len2 = $len2 - $len1 % 8;
	    $len2 -= $beginat;
	    my $len = $len2 - length($speed);
	    $speed .= $curSpeed x $len;
	    $speed .= $newSpeed;
	 }
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
	 $par =~ s/2/1/g;
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

	    my $tmp3 = unpack("B*", chr($warp25tableEnc{$checksum}));

	    $curTrack =~ s/-{10}/$tmp2/g;
	    $curTrack =~ s/_{8}/$tmp3/g;
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
      elsif ($line =~ /^warp25-raw (.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
	 my $last = 0;
	 
         my $tmp = pack("H*", $par);
	 my @tmp = unpack("C*", $tmp);
	 for my $i (@tmp)
	 {
	    my $val = $warp25tableEnc{$i ^ $last};
	    my $w25 = chr($val);
	    $last = $i;
	    $curTrack .= unpack("B*", $w25);
	    $checksum ^= $i if $checksumBlock == 1;
	 }
      }
      elsif ($line =~ /^warp25 (.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
	 my $last = 0;
	 
         my $tmp = pack("H*", $par);
	 $tmp = unpack("b*", $tmp);
	 my @tmp = (0,) x 320;
	 for (my $i=0; $i<320; $i++)
	 {
	    $tmp =~ s/^(.{6})//;
            my $sixbits = $1;
	    my $byte = 0;
	    $byte |= 1 if substr($sixbits,5,1);
	    $byte |= 2 if substr($sixbits,1,1);
	    $byte |= 4 if substr($sixbits,3,1);
	    $byte |= 8 if substr($sixbits,0,1);
	    $byte |= 32 if substr($sixbits,4,1);
	    $byte |= 64 if substr($sixbits,2,1);
	    
	    $tmp[$i] = $byte;
	 }
	 
	 for my $i (@tmp)
	 {
	    my $val = $warp25tableEnc{$i ^ $last};
	    my $w25 = chr($val);
	    $last = $i;
	    $curTrack .= unpack("B*", $w25);
	    $checksum ^= $i if $checksumBlock == 1;
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
      elsif ($line =~ /^warp25-checksum(.*)$/)
      {
         my $par = $1;
	 $par =~ s/ //g;
	 
	 if (length($par) == 8)
	 {
            $curTrack .= $par;
	 }
	 elsif ($par ne '')
	 {
            my $tmp = pack("H*", $par);
	    my @tmp = unpack("C*", $tmp);
	    for my $i (@tmp)
	    {
	       my $w25 = chr($warp25tableEnc{$i});
	       $curTrack .= unpack("B*", $w25);
	       $checksum ^= $i if $checksumBlock == 1;
	    }
	 }
	 else
	 {
	    $curTrack .= "_" x 8;
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
   
   my $g64 = "GCR-$format\0" . pack("C", $noTracks) . pack("S", $tracksizeHdr);
   $g64 .= "\0\0\0\0" x $noTracks;
   $g64 .= "\0\0\0\0" x $noTracks;
   
   for (my $i=1; $i<$noTracks; $i++)
   {
      next unless defined $tracks[$i];
      my $trackSpeed = $tracks[$i]->[0];
      my $trackContent = $tracks[$i]->[1];

      my $track2 = ($i+1)/2;
      my $trackTablePosition = 8+4*$i;
      my $speedTableOffset = 8+4*$noTracks + 4*$i;

      my $tmp = pack("L", length($g64));
      substr($g64, $trackTablePosition, 4) = $tmp;
      substr($g64, $speedTableOffset, 4) = pack("L", $trackSpeed) if length($trackSpeed) == 1;
      
      my $tmp = pack("B*", $trackContent);
      my $siz = length($tmp);
      my $tmpSize = pack("S", $siz);
      $g64 .= $tmpSize.$tmp.("\0" x ($tracksizeHdr-$siz));

      if (length($trackSpeed) > 1)
      {
         my $tmp = $trackSpeed;
	 my $trackSpeed2 = "";
	 while ($tmp ne "")
	 {
	    if ($tmp =~ s/^0{8}//)
	    {
	       $trackSpeed2 .= "00";
	    }
	    elsif ($tmp =~ s/^1{8}//)
	    {
	       $trackSpeed2 .= "01";
	    }
	    elsif ($tmp =~ s/^2{8}//)
	    {
	       $trackSpeed2 .= "10";
	    }
	    elsif ($tmp =~ s/^3{8}//)
	    {
	       $trackSpeed2 .= "11";
	    }
	    else
	    {
	       die "FIXME: speed not aligned\n".$tmp;
	    }
	 }
	 $tmp = pack("L", length($g64));
         substr($g64, $speedTableOffset, 4) = $tmp;
      
         my $tmp = pack("B*", $trackSpeed2);
         my $siz = length($tmp);
         $g64 .= $tmp.("\0" x ($tracksizeHdr-$siz));
      }
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
         my $extraspace = "";
	 if ($j == $s-1)
	 {
	    $extraspace = "   bytes" . (" 55" x 90) . "\n" if $i < 18;
	    $extraspace = "   bytes" . (" 55" x 264) . "\n" if $i >= 18 && $i < 25;
	    $extraspace = "   bytes" . (" 55" x 150) . "\n" if $i >= 25 && $i < 31;
	    $extraspace = "   bytes" . (" 55" x 96) . "\n" if $i > 30;
         }
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
	       .$extraspace
	       ."   bytes 55 55 55 55 55 55 55 55 ff\n";
	       
         $o += 256;
      }
      $ret .="end-track\n\n";
   }
   $ret;
}

sub stddisk1571
{
   my $ret = "no-tracks 168\ntrack-size 7928\n";
   my $i;
   my $o = 0;
   for ($i=1; $i<71; $i++)
   {
      my $t = $i;
      my $t2 = $i;
      if ($t > 35)
      {
         $t -= 35;
	 $t2 += 7;
      }
   
      my $s = 21;
      $s = 19 if $t >= 18;
      $s = 18 if $t >= 25;
      $s = 17 if $t >= 31;
      
      $ret .= "track $t2\n";
      $ret .= "   speed 3\n" if $s == 21;
      $ret .= "   speed 2\n" if $s == 19;
      $ret .= "   speed 1\n" if $s == 18;
      $ret .= "   speed 0\n" if $s == 17;
      $ret .= "   begin-at 0\n";
      
      my $j;
      for ($j = 0; $j < $s; $j++)
      {
         my $extraspace = "";
	 if ($j == $s-1)
	 {
	    $extraspace = "   bytes" . (" 55" x 90) . "\n" if $i < 18;
	    $extraspace = "   bytes" . (" 55" x 264) . "\n" if $i >= 18 && $i < 25;
	    $extraspace = "   bytes" . (" 55" x 150) . "\n" if $i >= 25 && $i < 31;
	    $extraspace = "   bytes" . (" 55" x 96) . "\n" if $i > 30;
         }
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
	       .$extraspace
	       ."   bytes 55 55 55 55 55 55 55 55 ff\n";
	       
         $o += 256;
      }
      $ret .="end-track\n\n";
   }
   $ret;
}



sub parseTrack2
{
   my $track = $_[0];
   
   my %sector = ();
   
   unless ($track =~ /^(.*?)(1111111111)(.*)$/ )
   {
      return {};
   }

   $track = "$2$3$1";
   
   if ($track =~ m/^(1+0101010111.*?)(1{9}.*)$/ )
   {
      $track = "$2$1";
   }
   
   $track =~ m/^(1{8})(.*)/;
   $track = "$2$1";

   my $revTrack = reverse $track;
   if ($revTrack =~m/^(1+)(1{9})(.*)$/)
   {
      $track = reverse "$2$3$1";
   }
   
   my $sector = undef;

   while ($track ne "")
   {
      # Remark: No need to test for > 9 bits cause we arranged that $track is starting with sync
      # which is continued from last "trackPart"!
      $track =~ s/^(1+)//;

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
	 my $trk = undef;
	 my $sec = undef;
	 
	 my $checksum = 0;
	 
         for (my $i=0; $i<7; $i++)
	 {
            my $v3 = $trackPart =~ s/^(.{5})//;
	    unless ($v3)
	    {
		  last;	       
	    }
	    my $e = $1;
            my $a = parseGCR($1);
            my $v4 = $trackPart =~ s/^(.{5})//;
	    unless ($v4)
	    {
		  last;	       
	    }
	    my $f = $1;
            my $b = parseGCR($1);
	    
	    if ($i < 5)
	    {
               if ((defined $a) && (defined $b) && (defined $checksum))
	       {
	          $checksum ^= hex("$a$b")
	       }
	       else
	       {
	          $checksum = undef;
	       }
	    }
	    
	    if ((defined $a) && (defined $b))
	    {
               $sec = "$a$b" if $i == 1;
	       $trk = "$a$b" if $i == 2;
	    }
	 }
	 if (defined($trk) && defined($sec))
	 {
	    if (defined $checksum)
	    {
	       if ($checksum == 0)
	       {
	          $sector = [ hex($trk), hex($sec) ];
	       }
	       else
	       {
	          $sector = undef;
	          $sector{hex($trk)}{hex($sec)} = 9;
	       }
	    }
	    else
	    {
	       $sector = undef;
	       $sector{hex($trk)}{hex($sec)} = 5;
	    }
	 }
      }
      elsif ($a.$b eq '07')
      {
	 my $gcr = "";
	 my $checksum = 0;
         for (my $i=0; $i<257; $i++)
	 {
            my $v3 = $trackPart =~ s/^(.{5})//;
	    unless ($v3)
	    {
		  last;	       
	    }
	    my $e = $1;
            my $a = parseGCR($1);
            my $v4 = $trackPart =~ s/^(.{5})//;
	    unless ($v4)
	    {
		  last;	       
	    }
	    my $f = $1;
            my $b = parseGCR($1);
	    
	    if ($i <= 256)
	    {
	       if ((defined $a) && (defined $b))
	       {
	          $gcr .= "$a$b" if $i < 256;
		  $checksum ^= hex("$a$b");
	       }
	       else
	       {
	          $gcr = 5;
		  last;
	       }
	    }
	 }

         if ($checksum)
	 {
	    $sector{ $sector->[0] }{ $sector->[1] } = 5;
	 }
	 else
	 {
            $sector{ $sector->[0] }{ $sector->[1] } = pack("H*", $gcr) if (defined $sector) && $gcr;
	 }
         $sector = undef;
      }
      else
      {
         $sector{ $sector->[0] }{ $sector->[1] } = 4 if defined $sector; 
         $sector = undef;
      }
      
      $track = $trackRest;
   }

   \%sector;
}


sub g64tod64
{
   my ($g64, $level) = @_;
   my $ret = ("\xDE\xAD\xBE\xEF" x 64) x 683;
   my $error = "\x02" x 683;
   
   my $signature = substr($g64, 0, 8);
   return undef unless ($signature eq 'GCR-1541' || $signature eq 'GCR-1571');

   return undef unless substr($g64, 8, 1) eq "\0";
   
   my $notracks = unpack("C", substr($g64, 9, 1));
   my $tracksizeHdr = unpack("S", substr($g64, 0xA, 2));
   
   my @tracks = ( 0, 21, 42, 63, 84, 105, 126, 147, 168, 189, 210, 231, 252, 273, 294, 315, 336, 357, 376, 395,
                  414, 433, 452, 471, 490, 508, 526, 544, 562, 580, 598, 615, 632, 649, 666, 683, 700, 717, 734,
		  751 ); 
   my @sectors = ( 21, 21, 21, 21, 21,  21, 21, 21, 21, 21,
                   21, 21, 21, 21, 21,  21, 21, 19, 19, 19,
		   19, 19, 19, 19, 18,  18, 18, 18, 18, 18,
		   17, 17, 17, 17, 17,  17, 17, 17, 17, 17);

   for (my $i=1; $i<=2*35; $i+=2)
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

      my $tmp = $trackContentHex;
      $tmp =~ s/ //g;
      my $trackBin = pack("H*", $tmp);
      my $trackContentBin = unpack("B*", $trackBin);
      $tmp = parseTrack2($trackContentBin);
      
      for my $t (sort { $a <=> $b } keys %$tmp)
      {
         next if $t < 1;
	 next if $t > 35;
	 my $tmp2 = $tmp->{$t};
	 for my $s (sort { $a <=> $b } keys %$tmp2)
	 {
	    next if $s > $sectors[$t-1];
	    my $offset1 = $tracks[$t-1] + $s;
	    my $offset2 = $offset1 * 256;
	    my $content = $tmp2->{$s};
	    if (length($content) == 256)
	    {
	       substr($ret, $offset2, 256) = $content;
	       substr($error, $offset1, 1) = "\1";
	    }
	    else
	    {
	       substr($error, $offset1, 1) = chr($content);
	    }
	 } 
      }      
   }
   
   return $ret if $error eq "\1" x 683;
   
   $ret.$error;
}

sub g64tod71
{
   my ($g64, $level) = @_;
   my $ret = ("\xDE\xAD\xBE\xEF" x 64) x 1366;
   my $error = "\x02" x 1366;
   
   my $signature = substr($g64, 0, 8);
   return undef unless ($signature eq 'GCR-1541' || $signature eq 'GCR-1571');

   return undef unless substr($g64, 8, 1) eq "\0";
   
   my $notracks = unpack("C", substr($g64, 9, 1));
   my $tracksizeHdr = unpack("S", substr($g64, 0xA, 2));
   
   my @tracks = (  ); 
   my @sectors = ( 21, 21, 21, 21, 21,  21, 21, 21, 21, 21,
                   21, 21, 21, 21, 21,  21, 21, 19, 19, 19,
		   19, 19, 19, 19, 18,  18, 18, 18, 18, 18,
		   17, 17, 17, 17, 17,  
		   
		   21, 21, 21, 21, 21,  21, 21, 21, 21, 21,
                   21, 21, 21, 21, 21,  21, 21, 19, 19, 19,
		   19, 19, 19, 19, 18,  18, 18, 18, 18, 18,
		   17, 17, 17, 17, 17, 
		 );

   for (my $i=0; $i<70; $i++)
   {
      my $s = 0;
      for (my $j=0; $j<$i; $j++)
      {
         $s += $sectors[$j];
      }
      $tracks[$i] = $s;
   }

   for (my $i=1; $i<=$notracks; $i+=2)
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

      my $tmp = $trackContentHex;
      $tmp =~ s/ //g;
      my $trackBin = pack("H*", $tmp);
      my $trackContentBin = unpack("B*", $trackBin);
      $tmp = parseTrack2($trackContentBin);
      
      for my $t (sort { $a <=> $b } keys %$tmp)
      {
         next if $t < 1;
	 next if $t > 70;
	 my $tmp2 = $tmp->{$t};
	 for my $s (sort { $a <=> $b } keys %$tmp2)
	 {
	    next if $s > $sectors[$t-1];
	    my $offset1 = $tracks[$t-1] + $s;
	    my $offset2 = $offset1 * 256;
	    my $content = $tmp2->{$s};
	    if (length($content) == 256)
	    {
	       substr($ret, $offset2, 256) = $content;
	       substr($error, $offset1, 1) = "\1";
	    }
	    else
	    {
	       substr($error, $offset1, 1) = chr($content);
	    }
	 } 
      }      
   }
   
   return $ret if $error eq "\1" x 1366;
   
   $ret.$error;
}

sub g64top64txt
{
   my ($g64, ) = @_;
   my $ret = "";
   
   my $signature = substr($g64, 0, 8);
   return undef unless ($signature eq 'GCR-1541' || $signature eq 'GCR-1571');

   return undef unless substr($g64, 8, 1) eq "\0";
   
   my $notracks = unpack("C", substr($g64, 9, 1));
   my $tracksizeHdr = unpack("S", substr($g64, 0xA, 2));
   
   $ret .= "sides 2\n" if $notracks >= 86;
   
   for (my $i=1; $i<$notracks; $i++)
   {
      my $track = ($i+1)/2;
      if ($track >= 43)
      {
         $track = ($track - 42) | 128;
      }
      my $p64track = $i+1;
      my $trackTablePosition = 8+4*$i;
      my $trackPosition = unpack("L", substr($g64, $trackTablePosition, 4));
      next unless $trackPosition;
      my $trackSize = unpack("S", substr($g64, $trackPosition, 2));
      my $trackContent = substr($g64, $trackPosition+2, $trackSize);
      
      my $trackContentHex = unpack("H*", $trackContent);
      $trackContentHex =~ s/(..)/ $1/gc;
      my $trackContentBin = unpack("B*", $trackContent);
      
      my $speedTableOffset = 8+4*$notracks + 4*$i;
      my $speed = unpack("L", substr($g64, $speedTableOffset, 4));
      # $p64data{$p64track} = [];
      
      if ($speed > 4)
      {
         my $tmp = substr($g64, $speed, $tracksizeHdr/4);
	 my $tmp2 = unpack("B*", $tmp);
	 $speed = "";
	 while (length($speed) < 8*$trackSize)
	 {
	    if ($tmp2 =~ s/^00//)
	    {
	       $speed .= "0" x 8;
	    }
	    elsif ($tmp2 =~ s/^01//)
	    {
	       $speed .= "1" x 8;
	    }
	    elsif ($tmp2 =~ s/^10//)
	    {
	       $speed .= "2" x 8;
	    }
	    elsif ($tmp2 =~ s/^11//)
	    {
	       $speed .= "3" x 8;
	    }
	 }
      }
      else
      {
         $speed = $speed x (8*$trackSize);
      }

      $ret .= "track $track\n";
      
      my $num0 = $speed =~ tr/0//;
      my $num1 = $speed =~ tr/1//;
      my $num2 = $speed =~ tr/2//;
      my $num3 = $speed =~ tr/3//;
      
      die if $num0+$num1+$num2+$num3 != 8*$trackSize;
      my $factor = (5*$num3/307692)+(5*$num2/285714)+(5*$num1/266667)+(5*$num0/250000);
      my $fluxPos = 1;      

      for (my $j=0; $j<8*$trackSize; $j++)
      {
         my $char = substr($trackContentBin, $j, 1);
	 my $sped = substr($speed, $j, 1);
	 if ($char)
	 {
            $ret .= "   flux $fluxPos\n";
	    # push (@{ $p64data{$p64track} }, $fluxPos);
	 }
	 if ($sped eq '0')
	 {
	    $fluxPos += ( 16000000 / 250000 ) / $factor;
	 }
	 if ($sped eq '1')
	 {
	    $fluxPos += ( 16000000 / 266667 ) / $factor;
	 }
	 if ($sped eq '2')
	 {
	    $fluxPos += ( 16000000 / 285714 ) / $factor;
	 }
	 if ($sped eq '3')
	 {
	    $fluxPos += ( 16000000 / 307692 ) / $factor;
	 }
      }
   }
   
   $ret;
}


sub reutog64
{
   my ($reu, $d64) = @_;

   my $tracksizeHdr = 7928;
   my $noTracks = 84;

   my @tracks = ();

   my $startTrack = unpack("C", substr($reu, 0, 1));
   my $endTrack = unpack("C", substr($reu, 1, 1));
   my $incTrack =    my $incTrack = unpack("C", substr($reu, 2, 1));
   my $reduceSyncs = unpack("C", substr($reu, 3, 1));
   
   my $trackPos = 8192;
   for (my $i=$startTrack; $i<=$endTrack; $i += $incTrack)
   {
      my $track = $i-1;
      my $speed = unpack("C", substr($reu, 3+$i, 1));
      my $rawTrack = substr($reu, $trackPos, 8192);
      my $rawTrackLen = index $rawTrack, "\0";

      if ($speed & 128)
      {
         $rawTrack = "\xFF" x 7820 if ($speed & 3) == 3;      
         $rawTrack = "\xFF" x 7170 if ($speed & 3) == 2;      
         $rawTrack = "\xFF" x 6300 if ($speed & 3) == 1;      
         $rawTrack = "\xFF" x 6020 if ($speed & 3) == 0;      
      }
      else
      {
         if ($rawTrackLen == -1)
	 {
	    $trackPos += 8192;
	    next;
	 }
      }
      $rawTrack = substr($rawTrack, 0, $rawTrackLen);
      $rawTrack = "\xFF\xFF\xFF".$rawTrack if !$reduceSyncs && ( $speed & 64 ) == 0;
      
      $tracks[$track] = [$speed & 3, $rawTrack];
      
      $trackPos += 8192;
   }

   my $g64 = "GCR-1541\0" . pack("C", $noTracks) . pack("S", $tracksizeHdr);
   $g64 .= "\0\0\0\0" x $noTracks;
   $g64 .= "\0\0\0\0" x $noTracks;
   
   for (my $i=1; $i<$noTracks; $i++)
   {
      next unless defined $tracks[$i];
      my $trackSpeed = $tracks[$i]->[0];
      my $trackContent = $tracks[$i]->[1];

      my $track2 = ($i+1)/2;
      my $trackTablePosition = 8+4*$i;
      my $speedTableOffset = 8+4*$noTracks + 4*$i;

      my $tmp = pack("L", length($g64));
      substr($g64, $trackTablePosition, 4) = $tmp;
      substr($g64, $speedTableOffset, 4) = pack("L", $trackSpeed);
      
      my $tmp = $trackContent;
      my $siz = length($tmp);
      my $tmpSize = pack("S", $siz);
      $g64 .= $tmpSize.$tmp.("\0" x ($tracksizeHdr/4-$siz));
   }
   
   $g64;
}






sub g64toreu
{
   my ($g64, $level) = @_;
   
   my $reu = "\0" x 8192;
   
   my $signature = substr($g64, 0, 8);
   return undef unless $signature eq 'GCR-1541';

   return undef unless substr($g64, 8, 1) eq "\0";
   
   my $notracks = unpack("C", substr($g64, 9, 1));
   my $tracksizeHdr = unpack("S", substr($g64, 0xA, 2));
   
   my $min = 9999;
   my $max = 0;
   
   for (my $i=1; $i<81; $i+=2)
   {
      my $track = ($i+1)/2;

      my $trackTablePosition = 8+4*$i;
      my $trackPosition = unpack("L", substr($g64, $trackTablePosition, 4));
      
      my $speedTableOffset = 8+4*$notracks + 4*$i;
      my $speed = unpack("L", substr($g64, $speedTableOffset, 4));

      $min = $i if $i < $min;
      $max = $i if $i > $max;
      
      if ($trackPosition)
      {
         my $trackSize = unpack("S", substr($g64, $trackPosition, 2));
         my $trackContent = substr($g64, $trackPosition+2, $trackSize);
      
         if ($speed > 4)
         {
            die;
         }
      
	 $trackContent =~ s/^\xFF+// if $level;
         my $tmp = $trackContent . ( "\0" x (8192-length($trackContent)) );
	 my $flags = 4;
	 $flags = 0x48 if index($trackContent, "\xFF") < 0;
	 die "Killertracks unsupported\n" if $trackContent =~ /^\xff+$/;
         substr($reu, 4+$i, 1) = chr($speed | $flags);
         $reu .= $tmp;
      }
      else
      {
         $reu .= (chr(55) x 6020) . ("\0" x (8192-6020));
         substr($reu, 4+$i, 1) = chr(0x42);
      }
   }
   
   substr($reu, 0, 4) = chr(2).chr(80).chr(2).chr( $level ? 0 : 255); 
   
   $reu;
}

sub nb2totxt
{
   my ($nb2, $level, $pass) = @_;
   my $ret = "";
   
   my $signature = substr($nb2, 0, 13);
   return undef unless ($signature eq 'MNIB-1541-RAW');


   for (my $i=1; $i<128; $i++)
   {
      my $track = ($i+1)/2;
      last if substr( $nb2, 256+8192*32*($track-1), 1) eq "";
      print STDERR "DEBUG: track=$track\n";

      for (my $speed = 0; $speed < 4; $speed++)
      {
              my $trackContent =  substr( $nb2, 256+8192*(32*($track-1)+4*$speed+$pass), 8192 );
              my $trackContentBin = unpack("B*", $trackContent);
           
              # This is not optimal, but fo rthe time being:
              $trackContentBin =~ s/^.*?1111111111/1111111111/;
              $trackContentBin = reverse $trackContentBin;
              $trackContentBin =~ s/^.*?1111111111/1111111111/;
              $trackContentBin =~ s/^1+//;
              $trackContentBin = reverse $trackContentBin;
              
              $ret .= "; track $track speed $speed pass $pass\n";
              $ret .= "rawtrack $track\n";
              $ret .= parseTrack($trackContentBin, $speed, $level, 0);  
      }
   }
   
   
   $ret;
}





### Flux related

sub parseKryofluxRawFile
{
   my $data = $_[0];
   my $pos = 0;
   my @res;
   my $ovl = 0;
   my @indicies = ();
   my $oobCount = 0;
   my $fluxSum = 0;
   
   my $sck = undef;
   my $ick = undef;
   
   while (1)
   {
   	my $type = unpack "C", substr $data, $pos, 1;
   	
   	if ($type < 8)   # Flux2
   	{
   	   my $val = unpack "n", substr $data, $pos, 2;
   	   $fluxSum += $val + $ovl;
   	   
   	   my %tmp = ();
   	   $tmp{Value} = $val + $ovl;
   	   $tmp{FluxSum} = $fluxSum;
   	   $tmp{streamPos} = $pos - $oobCount;
   	   
           push (@res, \%tmp);
   	   
   		$pos += 2;
   		$ovl = 0;
   	}
   	elsif ($type == 8)   # Nop1
   	{
   		$pos += 1;
   	}
   	elsif ($type == 9)   # Nop2
   	{
   		$pos += 2;
   	}
   	elsif ($type == 10)   # Nop3
   	{
   		$pos += 3;
   	}
   	elsif ($type == 11)   # Ovl16
   	{
              $ovl += 0x10000;
   		$pos += 1;
   	}
   	elsif ($type == 12)   # Flux3
   	{
   	   my $val = unpack "n", substr $data, $pos+1, 1;
           $fluxSum += $val + $ovl;

   	   my %tmp = ();
   	   $tmp{Value} = $val + $ovl;
   	   $tmp{streamPos} = $pos - $oobCount;
   	   $tmp{FluxSum} = $fluxSum;
           push (@res, \%tmp);
   	   
   		$pos += 3;
   		$ovl = 0;
   	}
   	elsif ($type == 13)   # OOB
   	{
   	   my $oobtype = unpack "C", substr $data, $pos+1, 1;
   	   my $oobsize = unpack "v", substr $data, $pos+2, 2;
   	   
   	   if ($oobtype == 0) # INVALID
   	   {
   	   	print "Warning: Invalid OOB type discovered\n";
   	   }
   	   elsif ($oobtype == 1) # STREAMINFO
   	   {
   	   	my $streamPos = unpack "V", substr $data, $pos+4, 4;
   	   	my $transferTime = unpack "V", substr $data, $pos+8, 4;
   	   	
   	   	my $tmp = $pos - $oobCount;
   	   	print "Error reading stream: Missed some data\n" unless $tmp == $streamPos;
   	   	
   	   }
   	   elsif ($oobtype == 2) # Index
   	   {
   	   	my $streamPos = unpack "V", substr $data, $pos+4, 4;
   	   	my $sampleCounter = unpack "V", substr $data, $pos+8, 4;
   	   	my $IndexCounter = unpack "V", substr $data, $pos+12, 4;
   	   	
   	        my %tmp = ();;
   	        $tmp{streamPos} = $streamPos;
   	        $tmp{sampleCounter} = $sampleCounter;
   	        $tmp{indexCounter} = $IndexCounter;
   	        
   	   	
   	   	push (@indicies, \%tmp);
   	   }
   	   elsif ($oobtype == 3) # StreamEnd
   	   {
   	   	my $streamPos = unpack "V", substr $data, $pos+4, 4;
   	   	my $resultCode = unpack "V", substr $data, $pos+8, 4;
   	   	my $tmp = $pos - $oobCount;
   	   	print "Error reading stream: Missed some data\n" unless $tmp == $streamPos;
   	   	print "Error reading stream; Code=$resultCode\n" unless $resultCode == 0;
   	   }
   	   elsif ($oobtype == 4) # KFInfo
   	   {
   	   	my $infotext = substr($data, $pos+4, $oobsize-1);
   	   	
   	   	if ($infotext =~ m/sck=([0-9\.]+)/ )
   	   	{
   	   		$sck = $1 - 0;
   	   	}
   	   	if ($infotext =~ m/ick=([0-9\.]+)/ )
   	   	{
   	   		$ick = $1 - 0;
   	   	}
   	   }
   	   elsif ($oobtype == 13) # EOF
   	   {
   	   	last;
   	   }
   	   
   	   $pos += 4+$oobsize;
   	   $oobCount += 4+$oobsize;
   		
   	}
   	else # Flux1
   	{
           $fluxSum += $type + $ovl;
   	   my %tmp = ();
   	   $tmp{Value} = $type + $ovl;
   	   $tmp{streamPos} = $pos - $oobCount;
   	   $tmp{FluxSum} = $fluxSum;
           push (@res, \%tmp);
      	   $pos += 1;
   		
           $ovl = 0;
   	}
   }
   
   my %ret;
   $ret{sck} = $sck;
   $ret{ick} = $ick;
   $ret{flux} = \@res;
   $ret{indicies} = \@indicies;
   
   \%ret;
}

sub extractRotation
{
   my ($content, $rotation) = @_;

   my $refIndicies = $content->{indicies};
   my $refFlux = $content->{flux};
   my $noRotations = scalar @$refIndicies;
   my $rotNo = -1;
   
   my %ret = ();
   
   for (my $i=0; $i<$noRotations-1; $i++)
   {
      my $streamPosInd = $refIndicies->[$i]{streamPos};
      my @index = grep { $_->{streamPos} < $streamPosInd  } @$refFlux;
      my $prevIndex1 = @index- 1;
      
      next if $prevIndex1 < 0;

      $streamPosInd = $refIndicies->[$i+1]{streamPos};
      @index = grep { $_->{streamPos} < $streamPosInd  } @$refFlux;
      my $prevIndex2 = @index - 1;

      next if $prevIndex1 >= @$refFlux - 1;

      $rotNo++;
      next if $rotNo != $rotation;
      
      my $bestError = undef;
      my $bestOffset = undef;
      
      for my $offset (-10..10)
      {
      	my $delta = abs ($refFlux->[$prevIndex2+$offset]{FluxSum} - $refFlux->[$prevIndex2]{FluxSum});
      	next if $delta > 300;
      	
      	my $err = 0;
      	
      	for my $i (-25..25)
      	{
           my $val1 = $refFlux->[$prevIndex1 + $i]{Value};
           my $val2 = $refFlux->[$prevIndex2 + $i + $offset]{Value};
           
           $err += abs($val1 - $val2);
      	}
      	
      	if ((!defined $bestError) || ($bestError > $err))
      	{
           $bestOffset = $offset;
           $bestError = $err;
      	}
      }
      
      $prevIndex2 += $bestOffset if defined $bestOffset;

      my $fluxSum = $refFlux->[$prevIndex2-1]{FluxSum} - $refFlux->[$prevIndex1-1]{FluxSum};
      

      $ret{index1} = $prevIndex1;
      $ret{index2} = $prevIndex2;
      
      $ret{adjustFlux1} = $refIndicies->[$i]{sampleCounter};
      $ret{adjustFlux2} = $refIndicies->[$i+1]{sampleCounter};
      
      $ret{fluxSum} = $fluxSum;
      $ret{tracktime} = $fluxSum / $content->{sck};;
      $ret{rpm} = 60 / $fluxSum * $content->{sck};;
      return \%ret;
   }
   
   undef;
}


sub kryofluxNormalize
{
   my ($fluxRaw, $flux0Metadata) = @_;
   
   my @ret = ();
   
   my $sck = $fluxRaw->{sck};
   my $idx1 = $flux0Metadata->{index1};
   my $idx2 = $flux0Metadata->{index2};
   my $rpm = $flux0Metadata->{rpm};
 
   ### FIXME: Position des allerersten Flux (Abstand Index)
   for (my $i=$idx1; $i < $idx2; $i++ )
   {
      my $val = $fluxRaw->{flux}[$i]{Value};
      $val = $val / $sck *5 * $rpm / 300;
      push (@ret, $val);
   }
   \@ret;
}

sub getSpeedZone
{
   my ($flux, $track) = @_;
   getSpeedZone1($flux);
}




sub getSpeedZone1
{
   my $flux = $_[0];	
   my @hist = (0) x 200;
   
   for my $v (@$flux)
   {
      my $vv = $v / 5 * 300 / 360;
      my $vvv = int $vv / 6.25e-8;
      next if $vvv >= 200;
      $hist[$vvv]++;
   }
   
   my $maxVal = 0;
   my $maxIdx = 0;
   for my $i (71..112)
   {
      my $v = $hist[$i];
      if ($v > $maxVal)
      {
      	$maxVal = $v;
      	$maxIdx = $i;
      }
   }
   
   return undef unless $maxVal;
   
   my $maxPos2 = $maxIdx * 6.25e-8;
   my $delta0 = abs(6.5625e-6 - $maxPos2);
   my $delta1 = abs(6.1875e-6 - $maxPos2);
   my $delta2 = abs(5.8125e-6 - $maxPos2);
   my $delta3 = abs(5.3125e-6 - $maxPos2);
   
   my $speed = undef;
   $speed=0 if $delta0 < $delta1 && $delta0 < $delta2 && $delta0 < $delta3;
   $speed=1 if $delta1 < $delta0 && $delta1 < $delta2 && $delta1 < $delta3;
   $speed=2 if $delta2 < $delta0 && $delta2 < $delta1 && $delta2 < $delta3;
   $speed=3 if $delta3 < $delta0 && $delta3 < $delta1 && $delta3 < $delta2;
   
   return undef unless defined $speed;
   
   my $delta = $delta0;
   $delta = $delta1 if $speed == 1;
   $delta = $delta2 if $speed == 2;
   $delta = $delta3 if $speed == 3;
   
   return undef if $delta > 0.3125e-6;
   $speed;
}

sub fluxtobitstream
{
   my ($flux, $speed) = @_;
   my $bits = "";
      
   
   my $pulseactive = 0;
   my $counterdelay = 0;
   my $bitwinremain = 0;
   my $bitcounter = 0;
   
   my $timePerBit = (4 - 0.25 * $speed)/1000000;
   my $timeUntilFirstBit = $timePerBit/2;
   
   for (my $i=0; $i<@$flux; $i++)
   {
      my $addBits = "";
      my $tmeToFlux = $flux->[$i] / 5;
      my $timeToFluxReduce = $tmeToFlux - $timeUntilFirstBit;
      my $tmeToFluxAddZeroes =  $tmeToFlux;
      
      my $read1 = ($counterdelay <= 0) && ($pulseactive <= 0);
      my $add0 = 1;
      
      if ($read1)
      {
         $add0 = $timeToFluxReduce > 0;
         $addBits .= "1";
         $counterdelay = $timeUntilFirstBit;
         $bitwinremain = 0;
         $bitwinremain = $tmeToFlux unless $add0;
         $bitcounter = 0;
         $tmeToFluxAddZeroes = $timeToFluxReduce;
      }

      $pulseactive = 2.5e-6;
      if ($add0)
      {
      	my $zerobits = "";
      	
      	$tmeToFlux += $bitwinremain;
      	my $zeroes = int $tmeToFluxAddZeroes / $timePerBit;
      	
      	$bitwinremain = $tmeToFluxAddZeroes - $zeroes * $timePerBit;
      	$zerobits = "0" x $zeroes;
      	
      	$addBits .= $zerobits;
      }
      $pulseactive -= $tmeToFlux;
      $counterdelay -= $tmeToFlux;

## print "$tmeToFlux     $addBits\n";
      $bits .= $addBits;
   }

   $bits;   
}

sub padbitstream
{
   my $bits = $_[0];
   return $bits if length($bits) % 8 == 0;
   
   my @parts = split(/(?<=111111111)(1{10,})/, $bits);
   my $check = join("", @parts);
   die unless $bits eq $check;
   
   my $bitsToAdd = 8 - length($bits) % 8;
   my $longestSync = 0;
   for my $i (@parts)
   {
      next if $i !~ /^1+$/;
      my $len = length $i;
      $longestSync = $len if $longestSync < $len;
   }
   
   my $longestSync2 = $longestSync;
   
   return $bits . ("0" x $bitsToAdd) if $longestSync == 0;

   while ($bitsToAdd > 0)
   {
      ## print "$longestSync   $longestSync2\n";
   	
      for my $i (@parts)
      {
         next if $i !~ /^[12]+$/;
         my $len = length $i;
         ### print "--- $len\n";
         next unless $len == $longestSync;
         $i .= '2';
         $bitsToAdd--;
         $longestSync2 = $len+1 if $longestSync < $len+1;
         last unless $bitsToAdd;
      }
      last unless $bitsToAdd;
      $longestSync--;
      $longestSync = $longestSync2 if $longestSync < 10;
   }
   
   join "", @parts;
}

sub reverseFlux
{
   my $flux = $_[0];
   my @flux = reverse @$flux;
   \@flux;
}






#### 

sub parseP64txt
{
   my ($p64txt,) = @_;
   my %ret = ();
   $ret{writeprotect} = 0;
   $ret{sides} = 1;
   $ret{tracks} = [];
   my $tracks = $ret{tracks};
   my $line;
   my $flux;
   
   open (my $file, "<", \$p64txt) or die;
   while ($line = <$file>)
   {
      chomp $line;
      $line =~ s/^ +//;
      if ($line eq "")
      {
      }
      elsif ($line =~ /^;/)
      {
      }
      elsif ($line =~  /^sides ([12])$/  )
      {
      	$ret{sides} = $1;
      }
      elsif ($line =~  /^write-protect ([01])$/  )
      {
      	$ret{writeprotect} = $1;
      }
      elsif ($line =~  /^track ([0-9]+(?:\.5)?)$/ )
      {
      	print "Parsing track $1\n";
      	my $mytrack = {};
      	$mytrack->{track} = $1;
      	$mytrack->{flux} = [];
      	$flux = $mytrack->{flux};
      	
      	push (@$tracks, $mytrack)
      }
      elsif ($line =~  /^flux ([0-9]+(?:\.[0-9]+)?)$/ )
      {
      	push (@$flux, $1);
      }
      else
      {
      	die "Invalid line $line\n";
      }
   }
   
   close ($file);
   \%ret;
}



sub normalizeP64Flux
{
   my ($flux,) = @_;
   my @ret = ();
   
   my $pos = $flux->[-1];
   for my $v (@$flux)
   {
      my $delta = $v - $pos;
      $delta += 3200000 if $delta < 0;
      push (@ret, $delta / 3200000);
      $pos = $v;
   }
 
   \@ret;
}

sub parseRange
{
   my $range = $_[0];
   	
   my @ret;
   
   my @range = split(",", $range);
   
   for my $range (@range)
   {
      if ( $range =~ /^([0-9]+)$/)
      {
         push (@ret, $1-0);
      }
      elsif ( $range =~ /^([0-9]+(?:\.5)?)\.\.([0-9]+(?:\.5)?)(?:\/([0-9]+(?:\.5)))?$/)
      {
      	my $a = $1-0;
      	my $b = $2-0;
      	my $c = $3;
      	unless (defined $c)
      	{
      	   my $d = $b-$a;
      	   $d -= int $d;
      	   if (abs($d) < 0.1)
      	   {
      	      $c=1;
      	   }
      	   else
      	   {
      	      $c=0.5;
      	   }
      	}
      	$c-=0;
      	
      	for (my $i=$a; $i<=$b; $i+=$c)
      	{
           push (@ret, $i);
        }
      }
      elsif ( $range =~ /^([0-9]+\.5)$/)
      {
         push (@ret, $1-0);
      }
      elsif ( $range =~ /^([0-9]+)\.\.([0-9]+)$/)
      {
      	my $a = $1-0;
      	my $b = $2-0;
         push (@ret, $a..$b);
      }
   }
   
   my %ret = map { $_ => 1 } @ret;
   
  \%ret;
}