#---------------------------------------------------------------------------
use strict;
use XML::Parser::Expat;
use HTTP::Date;
use Data::Dumper;
use POSIX qw{strftime};

$Data::Dumper::Indent = 1;
my %db;
my $currval;
my $l="-"x72 ."\n";

my $SportIdRunning=1;
my $SportIdTreadmill=8;
my $SportIdCycling=2;
my $SportIdCyclotrainer=7;
my $SportIdSwimming=3;
my $SportIdCore=10;
my $SModeRunning="111000100";
my $SModeCycling="111111100";
my $interactive="";

#---------------------------------------------------------------------------
my %guitext;
$guitext{sport}{$SportIdRunning}="Running";
$guitext{sport}{$SportIdTreadmill}="Treadmill";
$guitext{sport}{$SportIdCycling}="Cycling";
$guitext{sport}{$SportIdCyclotrainer}="Cyclotrainer";
$guitext{sport}{$SportIdCore}="Core";
$guitext{sport}{$SportIdSwimming}="Swimming";

#---------------------------------------------------------------------------
my $timeoffsetfit=str2time("1989-12-31T00:00:00Z");
my %exdb;
my %hrmdb;
my %pddb;
my $rcfgdb;
my $inTrack;
my $hasGPS;;
my $AltitudeMeters;
my $BuildMajor;
my $BuildMinor;
my $Builder;
my $DistanceMeters;
my $LapDistanceMeters;
my $HeartRateBpm;;
my $Id;
my $LangID;
my $Name;
my $PartNumber;
my $RunCadence;
my $Speed;
my $Sport;
my $StartTime;
my $Time;
my $TotalTimeSeconds;
my $Type;
my $Value;
my $VersionMajor;
my $VersionMinor;

#---------------------------------------------------------------------------
#initialise static settings
my $order=0;
$hrmdb{Params}{Version}{order}=$order++;
$hrmdb{Params}{Version}{payload}="106";
$hrmdb{Params}{Monitor}{order}=$order++;
$hrmdb{Params}{Monitor}{payload}="12";
$hrmdb{Params}{SMode}{order}=$order++;
$hrmdb{Params}{Date}{order}=$order++;
#$hrmdb{Params}{Date}{payload}="20100712";
$hrmdb{Params}{StartTime}{order}=$order++;
#$hrmdb{Params}{StartTime}{payload}="19:05:09.0";
$hrmdb{Params}{Length}{order}=$order++;
$hrmdb{Params}{Interval}{order}=$order++;
$hrmdb{Params}{Interval}{payload}="1";
$hrmdb{Params}{Upper1}{order}=$order++;
$hrmdb{Params}{Upper1}{payload}="0";
$hrmdb{Params}{Lower1}{order}=$order++;
$hrmdb{Params}{Lower1}{payload}="0";
$hrmdb{Params}{Upper2}{order}=$order++;
$hrmdb{Params}{Upper2}{payload}="0";
$hrmdb{Params}{Lower2}{order}=$order++;
$hrmdb{Params}{Lower2}{payload}="0";
$hrmdb{Params}{Upper3}{order}=$order++;
$hrmdb{Params}{Upper3}{payload}="0";
$hrmdb{Params}{Lower3}{order}=$order++;
$hrmdb{Params}{Lower3}{payload}="0";
$hrmdb{Params}{Timer1}{order}=$order++;
$hrmdb{Params}{Timer1}{payload}="00:00:00.0";
$hrmdb{Params}{Timer2}{order}=$order++;
$hrmdb{Params}{Timer2}{payload}="00:00:00.0";
$hrmdb{Params}{Timer3}{order}=$order++;
$hrmdb{Params}{Timer3}{payload}="00:00:00.0";
$hrmdb{Params}{ActiveLimit}{order}=$order++;
$hrmdb{Params}{ActiveLimit}{payload}="0";
$hrmdb{Params}{MaxHR}{order}=$order++;
$hrmdb{Params}{MaxHR}{payload}="190";
$hrmdb{Params}{RestHR}{order}=$order++;
$hrmdb{Params}{RestHR}{payload}="60";
$hrmdb{Params}{StartDelay}{order}=$order++;
$hrmdb{Params}{StartDelay}{payload}="0";
$hrmdb{Params}{VO2max}{order}=$order++;
$hrmdb{Params}{VO2max}{payload}="42";
$hrmdb{Params}{Weight}{order}=$order++;
$hrmdb{Params}{Weight}{payload}="74";

#---------------------------------------------------------------------------
#go through this section for deletion
my $aircraftType;
my $fuelType;
my $combatRadius;
my %AircraftModel; #key: aircraftType
my %AircraftConfiguration; #key: aircraftType, configurationId
my %AircraftConfigurationStoreItem;
my %OperatingLocation;
my %Runway;
my %geodetic;
my $datum;
my $height;
my $latitude;
my $longitude;
my $configurationId;
my $actionRadius;
my $externalFuelWeightCapacity;
my $storeItemCode;
my $itemQuantity;
my $weatherColorCode;
my $name;
my $elevation;
my $icao;
my $sep=",";
my $L="-"x75;
my $file;
my $fileprefix="xml-parser-expat";
my $datadir="./tmp";
my $fileAircraftModel="$fileprefix-AircraftModel.txt";
my $fileAircraftConfiguration="$fileprefix-AircraftConfiguration.txt";
my $fileAircraftConfigurationStoreItem="$fileprefix-AircraftConfigurationStoreItem.txt";
my $fileOperatingLocation="$fileprefix-OperatingLocation.txt";

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub fmt_time{
   my $t=shift;
   "$t [",strftime("\%Y-\%m-\%d \%H:\%M:\%S", localtime($t)),"]";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub mydump{
my $id=shift;
my $key=shift;
print "start: dump $key\n";
for $Time(sort keys %{$exdb{Activity}{$id}{Trackpoint}}){
   print "Time=$Time, $key=$exdb{Activity}{$id}{Trackpoint}{$Time}{$key}\n";
}
print "end: dump $key\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub smooth_exdb{
my $key;
my $last_val;
   for $Id(sort keys %{$exdb{Activity}}){
      #get start and end time
      my $t_start=1e20;
      my $t_end=-1;
      for $Time(keys %{$exdb{Activity}{$Id}{Trackpoint}}){
         $t_start=$Time if($t_start>$Time);
         $t_end=$Time if($t_end<$Time);
      }


      #---------------------------------------------------------------------
      #smooth out hrm data
      $key="HeartRateBpm";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};

      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 #if missing hrm data (<50bpm), then just set the value to the
	 #previously seen value
	 if($cur_val<50){


            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

      #---------------------------------------------------------------------
      $key="Speed";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};

      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
         #$log->debug("smooth: key=$key, Time=",fmt_time($Time),", value=",
         #   $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key},"\n");
	 if($cur_val>2*$last_val && $last_val>1.0){


            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

      #---------------------------------------------------------------------
      $key="AltitudeMeters";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};


      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
         #
         #   $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key},"\n");
	 if($cur_val>($last_val+10) || $cur_val<($last_val-10)){


            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

      #---------------------------------------------------------------------
      $key="RunCadence";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};

      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 if($cur_val>($last_val*1.10)){

            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=($cur_val+$last_val)/2;
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

   }
}


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub extrapolate_exdb{
   for $Id(sort keys %{$exdb{Activity}}){
      #get start and end time
      my $t_start=1e20;
      my $t_end=-1;
      for $Time(keys %{$exdb{Activity}{$Id}{Trackpoint}}){
         $t_start=$Time if($t_start>$Time);
         $t_end=$Time if($t_end<$Time);
      }

      for my $key(qw(AltitudeMeters Speed DistanceMeters RunCadence HeartRateBpm)){

         #------------------------------------------------------------------


         #------------------------------------------------------------------
	 #make sure first trackpoint has a value for this key
	 $Time=$t_start;
         while($Time < $t_end &&
	    !defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){$Time++;}
         if($Time==$t_end){
	    #no values found, skip to next key

	    next;
	 }
	 my $v_start=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};

	 while(--$Time ge $t_start){


	    $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$v_start;
	 }

         #------------------------------------------------------------------
	 #make sure last trackpoint has a value for this key
	 $Time=$t_end;
         while(!defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){$Time--;}
	 my $v_end=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};


	 while(++$Time le $t_end){

	    $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$v_end;
	 }

         #------------------------------------------------------------------
	 my $t_missing="";
	 $Time=$t_start;
         while($Time<=$t_end){
            if(!defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){
	       $t_missing=$Time;
	       $Time++;
               while(!defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){
	          $Time++;

               }
               $v_start=$exdb{Activity}{$Id}{Trackpoint}{$t_missing-1}{$key};
               $v_end=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};

	      for(my $t=0;$t<$Time-$t_missing;$t++){
	         my $v=$v_start+($v_end-$v_start)/($Time-$t_missing+1)*($t+1);

	      }
	    }
	    else{
	       $Time++;
	       #$log->debug("expol: ok - Time=$Time",fmt_time($Time));
	    }
         }
      }
   }
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub populate_hrmdb{

#---------------------------------------------------------------------------
#populate from cfgdb
@{$hrmdb{HRZones}}=@{$$rcfgdb{USER}{HRZONES}};

for $Id(sort keys %{$exdb{Activity}}){
   #print "populate_hrmdb: Id=$Id\n";

   #------------------------------------------------------------------------
   #populate the HRData section of the hrm structure
   for $Time(sort keys %{$exdb{Activity}{$Id}{Trackpoint}}){
      my $hr=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm};
      my $speed=int 0.5+36*$exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed};
      my $cadence=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence};
      my $altitude=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters};
      my $power=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{Power};

      push @{$hrmdb{HRData}},[$hr,$speed,$cadence,$altitude,$power];
   }

   #------------------------------------------------------------------------
   #populate IntTimes section and some of the Param section in the hrm structure
   my $totaltime;
   my $totaldistance;
   my $firstlapstarttime;

   for $Time(sort keys %{$exdb{Activity}{$Id}{Lap}}){
      $firstlapstarttime=$Time if(!$firstlapstarttime);
      my $laptime=$exdb{Activity}{$Id}{Lap}{$Time}{TotalTimeSeconds};
      my $lapdistance=$exdb{Activity}{$Id}{Lap}{$Time}{DistanceMeters};
      $totaltime+=$laptime;

      $totaldistance+=$lapdistance;
      my $laptimestr=strftime("\%H:\%M:\%S.0", gmtime($totaltime));

   }
   $hrmdb{Params}{Length}{payload}=strftime("\%H:\%M:\%S.0", gmtime($totaltime));
   $hrmdb{Params}{Date}{payload}=strftime("\%Y\%m\%d", localtime($firstlapstarttime));
   $hrmdb{Params}{StartTime}{payload}=strftime("\%H:\%M:\%S.0", localtime($firstlapstarttime));
   $hrmdb{SPORTID}=$exdb{Activity}{$Id}{SportId};
   $hrmdb{Params}{SMode}{payload}=$exdb{Activity}{$Id}{SMode};
   $hrmdb{DISTANCE}=$totaldistance;
   $hrmdb{STARTTIME}=$firstlapstarttime;
   $hrmdb{TOTALTIME}=$totaltime;
   #$hrmdb{HRMFILE}=strftime("\%y\%m\%d01.hrm", localtime($firstlapstarttime));

   $hrmdb{DTG0}=strftime("\%Y\%m\%d", localtime($firstlapstarttime));
   $hrmdb{DTG1}=strftime("\%Y-\%m-\%d", localtime($firstlapstarttime));
   $hrmdb{DTG2}=strftime("\%Y-\%m-\%d \%H:\%M:\%S", localtime($firstlapstarttime));
}

my $dist=int $hrmdb{DISTANCE}/100; #round to two spots and turn into hectometers. Fucking seriously? hectometers?
my $allTime=$exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds};
push @{$hrmdb{Trip}},[$dist];
push @{$hrmdb{Trip}},[0];
push @{$hrmdb{Trip}},[$allTime];
push @{$hrmdb{Trip}},[0];
push @{$hrmdb{Trip}},[0];
push @{$hrmdb{Trip}},[0];
push @{$hrmdb{Trip}},[0];
push @{$hrmdb{Trip}},[0];
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub user_interaction{
print  "$l";
print  "Date....: ",strftime("\%Y-\%m-\%d",localtime($hrmdb{STARTTIME})),"\n";
print  "Start...: ",strftime("\%H:\%M",localtime($hrmdb{STARTTIME})),"\n";
print  "Sport...: ",$guitext{sport}{$hrmdb{SPORTID}},"\n";
print  "Duration: $hrmdb{Params}{Length}{payload}\n";
printf "Distance: %.1fkm\n", $hrmdb{DISTANCE}/1000.0;
my $lapnum;
my %lapdata;
my $lapstr;
for $Id(sort keys %{$exdb{Activity}}){
   print  "$l";
   for $StartTime(sort keys %{$exdb{Activity}{$Id}{Lap}}){
      $lapnum++;
      $lapstr=sprintf("#%d: ",$lapnum);
      my $seconds=$exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds};
      if($seconds>60*60){
         $lapstr.=strftime("\%H:\%M:\%S",gmtime($seconds));
      }
      else{
         $lapstr.=strftime("\%M:\%S",gmtime($seconds));
      }
      my $distkm=$exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}/1000.0;
      $lapstr.=sprintf(", %.1fkm, ",$distkm);
      if($exdb{Activity}{$Id}{SportId} eq $SportIdRunning or
        $exdb{Activity}{$Id}{SportId} eq $SportIdTreadmill){
         $lapstr.=strftime("\%M:\%Smin/km",gmtime($seconds/$distkm))
	    if($distkm>0);
      }
      else{
         $lapstr.=sprintf("%.1fkm/t, ",$distkm/($seconds/3600.0));
         $lapstr.=sprintf("avg %dW, ",$exdb{Activity}{$Id}{Lap}{$StartTime}{PowerAvg});
         $lapstr.=sprintf("avg %dbpm, ",$exdb{Activity}{$Id}{Lap}{$StartTime}{HeartAvg});
         $lapstr.=sprintf("avg %drpm ",$exdb{Activity}{$Id}{Lap}{$StartTime}{CadenceAvg});
      }
      $lapdata{$lapnum}=$lapstr;
      print "$lapstr\n";
   }
}
#print  "Exercise: "; $hrmdb{EXERCISE}=<STDIN>; chomp $hrmdb{EXERCISE};

#---------------------------------------------------------------------------
return 1 if(!$interactive);
print  "${l}Add this session to Polar ProTrainer? [y, n] ";
my $answer=<STDIN>;chomp $answer;
if($answer eq "y"){
   print  "Comment.: ";
   my $note=<STDIN>; chomp $note;
   print "Include laps? [n; all; 1,3,7,...]: ";
   $answer=<STDIN>;chomp $answer;
   if($answer ne "n" and $answer ne ""){
      $note.=" Runder: ";
      if($answer eq "all"){
         $note.=join "; ", map{$lapdata{$_}} sort{$a<=>$b}keys %lapdata;
      }
      else{
         for my $lap(split(",",$answer)){
	    if(0<$lap and $lap<=$lapnum){
               $note.="$lapdata{$lap}; ";
	    }
	    else{
	       print "ignoring illegal lap: $lap\n";
	    }
	 }
      }
   }
   $hrmdb{NOTE}=$note; #for the pdd file
   #push @{$hrmdb{Note}},[$note]; #for the hrm file
   return 1;
}
else{
   print "Skipping session...\n";
   return "";
}
}

#---------------------------------------------------------------------------
#tbd - using xml::parser is not optimal for generating xml file, because
#you need to manually get all the values and output as xml.
#---------------------------------------------------------------------------
sub gen_tcxfile{

my $tcxfileout="/tmp/out.tcx";

#---------------------------------------------------------------------------
open TCX,">$tcxfileout" or die "cannot create $tcxfileout";
print TCX<<EOT
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<TrainingCenterDatabase
xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.garmin.com/xmlschemas/ActivityExtension/v2
http://www.garmin.com/xmlschemas/ActivityExtensionv2.xsd
http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2
http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd">
EOT
;
print TCX "<Activities>\n";
print TCX "</Activities>\n";
print TCX <<EOT;
 <Author xsi:type="Application_t">
    <Name>$exdb{Author}{Name}</Name>
    <Build>
      <Version>
        <VersionMajor>$exdb{Author}{Build}{Version}{VersionMajor}</VersionMajor>
        <VersionMinor>$exdb{Author}{Build}{Version}{VersionMinor}</VersionMinor>
        <BuildMajor>$exdb{Author}{Build}{Version}{BuildMajor}</BuildMajor>
        <BuildMinor>$exdb{Author}{Build}{Version}{BuildMinor}</BuildMinor>
      </Version>
      <Type>$exdb{Author}{Build}{Type}</Type>
      <Time>$exdb{Author}{Build}{Time}</Time>
      <Builder>$exdb{Author}{Build}{Builder}</Builder>
    </Build>
    <LangID>$exdb{Author}{LangID}</LangID>
    <PartNumber>$exdb{Author}{PartNumber}</PartNumber>
  </Author>
EOT
;
print TCX "</Author>\n";
print TCX "</TrainingCenterDatabase>\n";
close TCX;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub gen_hrmfile{
#---------------------------------------------------------------------------

my $dtg=strftime("\%y\%m\%d", localtime($hrmdb{STARTTIME}));
#$log->debug("gen_hrmfile: hrmdb{STARTTIME}=$hrmdb{STARTTIME}, localtime(.)=", localtime($hrmdb{STARTTIME}));

my $hrmfile="${dtg}01.hrm";
my $i=2;
while(-f "$ENV{POLARDIR}/$hrmfile"){
   $hrmfile=sprintf "$dtg%02d.hrm", $i++;
}

$hrmdb{HRMFILE}=$hrmfile;
open HRM,">$ENV{POLARDIR}/$hrmfile" or die "cannot create $hrmfile";
print "creating $hrmfile...\n\n\n";
for my $s(qw(Params)){
   print HRM qq([$s]\r\n);
   for my $key(sort{$hrmdb{$s}{$a}{order} <=> $hrmdb{$s}{$b}{order}} keys %{$hrmdb{$s}}){
      print HRM qq($key=$hrmdb{$s}{$key}{payload}\r\n);
   }
   print HRM "\r\n";
}
for my $s(qw(Note IntTimes ExtraData Summary-123 Summary-TH
             HRZones SwapTimes Trip HRData)){
   print HRM qq([$s]\r\n);
   for my $aref(@{$hrmdb{$s}}){
      my $l=join "\t",@$aref;
      print HRM "$l\r\n";
   }
   print HRM "\r\n";
}

close HRM;
}


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub populate_pddb{
my $pddfile="$ENV{POLARDIR}/$hrmdb{PDDFILE}";
if(-f $pddfile){
   open PDD,"<$pddfile" or die "cannot open $pddfile";
   print "reading existing $hrmdb{PDDFILE}...\n";
   my $section;
   while(<PDD>){
      chomp;
      #---------------------------------------------------------------------
      #search for [DayInfo], [ExerciseInfo1], [ExePlanInfo1] etc
      if(m/\[(.*)\]/){
         $section=$1;


         #------------------------------------------------------------------
	 #save the list of ExerciseInfo1,2,3,... sections seen
         if($section=~m/ExerciseInfo/){
            push @{$pddb{EXERCISEINFOLIST}},$section;
            $pddb{EXERCISECOUNT}++;
	 }
         #------------------------------------------------------------------
	 #save the list of ExePlanInfo1,2,3,... sections seen
         if($section=~m/ExePlanInfo/){
            push @{$pddb{EXEPLANINFOLIST}},$section;
            $pddb{EXEPLANCOUNT}++;
	 }
      }
      else{
         #------------------------------------------------------------------
         #not a section line, so push the contents of the line onto the
	 #array of arrays defined for the hash entry for this section
         push @{$pddb{$section}},[split /\t/,$_] if ($section);
      }
   }
   close PDD;
}

#---------------------------------------------------------------------------
#add a new ExerciseInfo section for the exercise added now; must increase
#the section number by one first..
my $i=1;
my $e="ExerciseInfo$i";
while(defined $pddb{$e}){
   $e="ExerciseInfo". ++$i;
}

#---------------------------------------------------------------------------
#set distance to 0 for Core workout
#$hrmdb{DISTANCE}=0 if ($hrmdb{SPORTID} == $SportIdCore);

#---------------------------------------------------------------------------
#add the section here, and then a list of dummy data (for now)
push @{$pddb{EXERCISEINFOLIST}},$e;
$pddb{EXERCISECOUNT}++;
#print "count=$pddb{EXERCISECOUNT}\n";
push @{$pddb{$e}},[101,1,24,6,12,512], #row 0
[0,0,0,int($hrmdb{DISTANCE}),
int($hrmdb{STARTTIME} -
   str2time(strftime("\%Y-\%m-\%dT00:00:00", localtime($hrmdb{STARTTIME})))),
int($hrmdb{TOTALTIME})], #row 1
[$hrmdb{SPORTID},0,0,2,0,364], #row 2
[int($hrmdb{DISTANCE}),0,0,0,0,55], #row 3
[2,0,0,0,0,0], #row 4
[0,0,0,0,56,174], #row 5
[2540,0,0,0,0,10007], #row 6
[0,0,0,0,1,2], #row 7
[0,0,0,0,1,0], #row 8
[131,163,100,156,75,81], #row 9
[91,117,0,0,0,0], #row 10
[0,0,0,0,0,45], #row 11
[473,0,6050,0,0,364], #row 12
[0,0,0,0,0,0], #row 13
[0,0,0,0,0,0], #row 14
[0,0,0,0,0,0], #row 15
[0,0,0,0,0,0], #row 16
[0,0,0,0,0,0], #row 17
[0,0,0,0,0,0], #row 18
[0,0,0,0,0,0], #row 19
[0,0,0,0,0,0], #row 20
[0,0,0,0,0,0], #row 21
[0,0,0,0,0,0], #row 22
[0,0,0,0,0,0], #row 23
[0,0,0,0,0,0], #row 24
[$hrmdb{EXERCISE}], #text row 0
[$hrmdb{NOTE}],     #text row 1
[$hrmdb{HRMFILE}],  #text row 2
[], #text row 3
[], #text row 4
[], #text row 5
[], #text row 6
[], #text row 7
[], #text row 8
[], #text row 9
[], #text row 10
[], #text row 11
[], #text row 12
;
if(!defined $pddb{DayInfo}){
push @{$pddb{DayInfo}},[100,1,7,6,1,512],
[$hrmdb{DTG0},$pddb{EXERCISECOUNT},0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[],
;
#day note in empty line above
}
else{
   ${$pddb{DayInfo}}[1][1]=$pddb{EXERCISECOUNT};
}
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub parse_fitcsvfile{
my $fitcsvfile="$ENV{FITCSVDIR}/$ENV{INFILEBASE}.csv";
$Id="fit";
open CSV, "<$fitcsvfile" or die "cannot open $fitcsvfile";

#---------------------------------------------------------------------------
#field position in Data and Record line from csf file
my $iTimeLap;my $iTimeRecord;
my $iStarttimeLap;
my $iTotalttimesecondsLap;
my $iLapdistancemetersLap;
my $iSpeedavgLap; my $iSpeedmaxLap;
my $iPoweravgLap; my $iPowermaxLap;
my $iHeartrateavgLap; my $iHeartratemaxLap;
my $iCadenceavgLap; my $iCadencemaxLap;

my $iDistanceRecord; my $iSpeedRecord; my $iHeartrateRecord;
my $iCadenceRecord; my $iTemperatureRecord; my $iAltitudeRecord;
my $iPowerRecord; my $iSportRecord;

#---------------------------------------------------------------------------
#read until we find the first lap line and record line
seek(CSV,0,0);
my $seenlap;
my $seenrecord;
while(<CSV>){
   if(m/Data,\d+,lap,/ and !$seenlap){
      my @l=split /,/;

      $seenlap=1;
      #---------------------------------------------------------------------
      #analyse the record to find the indeces to use
      for(my $i=0;$i<$#l;$i++){

	 my $field=$l[$i];
	 if($field eq "timestamp"){
	    $iTimeLap=$i+1;

	 }
	 elsif($field eq "start_position_lat"){
	    $hasGPS=1;

	 }
	 elsif($field eq "start_position_long"){
	    $hasGPS=1;

	 }
	 elsif($field eq "start_time"){
	    $iStarttimeLap=$i+1;

	 }
	 elsif($field eq "total_elapsed_time"){
	    $iTotalttimesecondsLap=$i+1;

	 }
	 elsif($field eq "total_distance"){
	    $iLapdistancemetersLap=$i+1;

	 }
	 elsif($field eq "avg_speed"){
	    $iSpeedavgLap=$i+1;

	 }
	 elsif($field eq "max_speed"){
	    $iSpeedmaxLap=$i+1;

	 }
	 elsif($field eq "avg_power"){
	    $iPoweravgLap=$i+1;

	 }
	 elsif($field eq "max_power"){
	    $iPowermaxLap=$i+1;

	 }
	 elsif($field eq "avg_heart_rate"){
	    $iHeartrateavgLap=$i+1;

	 }
	 elsif($field eq "max_heart_rate"){
	    $iHeartratemaxLap=$i+1;

	 }
	 elsif($field eq "avg_cadence"){
	    $iCadenceavgLap=$i+1;

	 }
	 elsif($field eq "max_cadence"){
	    $iCadencemaxLap=$i+1;

	 }
      }

   }
   if(m/Data,\d+,record,/ and !$seenrecord){
      my @l=split /,/;

      #---------------------------------------------------------------------
      #analyse the record to find the indeces to use
      for(my $i=0;$i<$#l;$i++){

	 my $field=$l[$i];
	 if($field eq "timestamp"){
	    $iTimeRecord=$i+1;

	 }
	 if($field eq "distance"){
	    $iDistanceRecord=$i+1;

	 }
	 elsif($field eq "start_position_lat"){
	    $hasGPS=1;

	 }
	 elsif($field eq "start_position_long"){
	    $hasGPS=1;

	 }
	 elsif($field eq "altitude"){
	    $iAltitudeRecord=$i+1;

	 }
	 elsif($field eq "speed"){
	    $iSpeedRecord=$i+1;

	 }
	 elsif($field eq "power"){
	    $iPowerRecord=$i+1;

	 }
	 elsif($field eq "heart_rate"){
	    $iHeartrateRecord=$i+1;

	 }
	 elsif($field eq "cadence"){
	    $iCadenceRecord=$i+1;

	 }
	 elsif($field eq "temperature"){
	    $iTemperatureRecord=$i+1;

	 }
	 elsif($field eq "sport"){
	    $iSportRecord=$i+1;

	 }
      }
      if($iDistanceRecord &&
         $iAltitudeRecord &&
         $iSpeedRecord &&
         $iPowerRecord &&
         $iCadenceRecord &&
         $iTemperatureRecord &&
	 1){
         $seenrecord=1;

      }
      else{

      }
   }
   if($seenlap and $seenrecord){
      last; #skip reading more entries
   }
}

#---------------------------------------------------------------------------
#start from the top of the file again
seek(CSV,0,0);
while(<CSV>){
   my @l;
   if(m/Data,\d+,lap,/){
      @l=split /,/;
      #print strftime("\%H:\%M:\%S", localtime($l[$iTimeLap])),",";
      $Time=$l[$iTimeLap]+$timeoffsetfit;
      $StartTime=$l[$iStarttimeLap]+$timeoffsetfit;
      $TotalTimeSeconds=$l[$iTotalttimesecondsLap];
      $LapDistanceMeters=$l[$iLapdistancemetersLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}=$LapDistanceMeters;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{SpeedAvg}=$l[$iSpeedavgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{SpeedMax}=$l[$iSpeedmaxLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{PowerAvg}=$l[$iPoweravgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{PowerMax}=$l[$iPowermaxLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{HeartAvg}=$l[$iHeartrateavgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{HeartMax}=$l[$iHeartratemaxLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{CadenceAvg}=$l[$iCadenceavgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{CadenceMax}=$l[$iCadencemaxLap];
   }
   elsif(m/Data,\d+,record,/){
      @l=split /,/;
      #print strftime("\%H:\%M:\%S", localtime($l[$iTimeRecord])),",";
      $Time=$l[$iTimeRecord]+$timeoffsetfit;
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$l[$iDistanceRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters}=$l[$iAltitudeRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed}=$l[$iSpeedRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Power}=$l[$iPowerRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm}=$l[$iHeartrateRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence}=$l[$iCadenceRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Temperature}=$l[$iTemperatureRecord];

      #$log->debug("parse_fit: t=$Time,d=$exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters},a=$exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters},v=$exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed},p=$exdb{Activity}{$Id}{Trackpoint}{$Time}{Power},hr=$exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm},cd=$exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence},tmp=$exdb{Activity}{$Id}{Trackpoint}{$Time}{Temperature}");
   }
}
close CSV;

#---------------------------------------------------------------------------
#determine the sport
$fitcsvfile="$ENV{FITCSVDIR}/$ENV{INFILEBASE}_laps.csv";
open CSV, "<$fitcsvfile" or die "cannot open $fitcsvfile";
my @l;
while(<CSV>){
   @l=split /,/;
}
my $text=$l[3];

if($text eq "GENERIC"){
   $exdb{Activity}{$Id}{SportId}=$SportIdCore;
   #$exdb{Activity}{$Id}{SMode}=????;
}
elsif($text eq "SWIMMING"){
   $exdb{Activity}{$Id}{SportId}=$SportIdSwimming;
}
elsif($text eq "RUNNING"){
   if($hasGPS){
      $exdb{Activity}{$Id}{SportId}=$SportIdRunning;
   }
   else{
      $exdb{Activity}{$Id}{SportId}=$SportIdTreadmill;
   }
   $exdb{Activity}{$Id}{SMode}=$SModeRunning;
}
elsif($text eq "CYCLING"){
   if($hasGPS){
      $exdb{Activity}{$Id}{SportId}=$SportIdCycling;
   }
   else{
      $exdb{Activity}{$Id}{SportId}=$SportIdCyclotrainer;
   }
   $exdb{Activity}{$Id}{SMode}=$SModeCycling;
}


}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub parse_tcxfile{
#---------------------------------------------------------------------------
#create parser object which is namespace-aware
my $parser = new XML::Parser::Expat('Namespaces' =>1);

#---------------------------------------------------------------------------
#set handlers for tags and data
$parser->setHandlers('Start' => \&start_element,
                     'End'   => \&end_element,
                     'Char'  => \&char_data,
                     );

#---------------------------------------------------------------------------
#parse the tcx file
my $tcxfilein="$ENV{INFILE}";
open TCX,"<$tcxfilein" or die "cannot open $tcxfilein";
#print "parsing $tcxfilein...\n";
$parser->parse(*TCX);
close(TCX);

#---------------------------------------------------------------------------
} #sub parse_tcxfile


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub char_data{
   my ($p,$string)=@_;
   $currval=$string;
   $currval=~s/^\s*//;
   $currval=~s/\s*$//;
   #print "char_data: currval=$currval\n" if($currval);
}

#---------------------------------------------------------------------------
#called by parser->parse on the start of every xml tag
#---------------------------------------------------------------------------
sub start_element{
   my ($p, $el, %atts) = @_;
   if($el eq "Activity"){
      $Sport=$atts{Sport};
   }
   elsif($el eq "Lap"){
      $StartTime=str2time($atts{StartTime});
   }
   elsif($el eq "Track"){
      $inTrack="true";
   }
   elsif($el eq "Position"){
      $hasGPS="true";
   }
   #print "start_element: el=$el\n";
}

#---------------------------------------------------------------------------
#called by parser->parse on the end of every xml tag
#---------------------------------------------------------------------------
sub end_element{
   my ($p, $el) = @_;
   #print "end_element: el=$el\n";
   if($el eq "Activity"){

      $exdb{Activity}{$Id}{Sport}=$Sport;
      if($Sport eq "Running"){

         if($hasGPS){
	    #has GPS data, probably from running outside
	    $exdb{Activity}{$Id}{SportId}=$SportIdRunning;
	 }
	 else{
	    #has no GPS data, probably from running on a treadmill
	    $exdb{Activity}{$Id}{SportId}=$SportIdTreadmill;
	 }
	 $exdb{Activity}{$Id}{SMode}=$SModeRunning;

      }
      elsif($Sport eq "Other"){
	 $exdb{Activity}{$Id}{SportId}=$SportIdCore;

      }
      else{

	 exit 1;
      }
   }
   elsif($el eq "Lap"){
      #print "Lap completed: TotalTimeSeconds=$TotalTimeSeconds\n";
      $exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}=$LapDistanceMeters;
   }
   elsif($el eq "Trackpoint"){
      #print "Trackpoint completed: Time=$Time\n";
      $Time=str2time($Time);
      if(!$Time){
         print "Warning: error converting Time - skipping\n";
	 return;
      }
      if("$DistanceMeters"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$DistanceMeters;
         $DistanceMeters="";
      }
      if("$Speed"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed}=$Speed;
         $Speed="";
      }
      if("$RunCadence"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence}=$RunCadence;
         $RunCadence="";
      }
      if("$HeartRateBpm"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm}=$HeartRateBpm;
         $HeartRateBpm="";
      }
      if("$AltitudeMeters"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters}=$AltitudeMeters;
         $AltitudeMeters="";
      }
   }
   elsif($el eq "Track"){
      $inTrack="";
   }
   elsif($el eq "Name"){
      $Name=$currval;
   }
   elsif($el eq "Type"){
      $Type=$currval;
   }
   elsif($el eq "Time"){
      $Time=$currval;
   }
   elsif($el eq "Builder"){
      $Builder=$currval;
   }
   elsif($el eq "LangID"){
      $LangID=$currval;
   }
   elsif($el eq "PartNumber"){
      $PartNumber=$currval;
   }
   elsif($el eq "VersionMajor"){
      $VersionMajor=$currval;
   }
   elsif($el eq "VersionMinor"){
      $VersionMinor=$currval;
   }
   elsif($el eq "BuildMajor"){
      $BuildMajor=$currval;
   }
   elsif($el eq "BuildMinor"){
      $BuildMinor=$currval;
   }
   elsif($el eq "Version"){
      $exdb{Author}{Build}{Version}{VersionMajor}=$VersionMajor;
      $exdb{Author}{Build}{Version}{VersionMinor}=$VersionMinor;
      $exdb{Author}{Build}{Version}{BuildMajor}=$BuildMajor;
      $exdb{Author}{Build}{Version}{BuildMinor}=$BuildMinor;
   }
   elsif($el eq "Build"){
      $exdb{Author}{Build}{Type}=$Type;
      $exdb{Author}{Build}{Time}=$Time;
      $exdb{Author}{Build}{Builder}=$Builder;
   }
   elsif($el eq "Author"){
      $exdb{Author}{Name}=$Name;
      $exdb{Author}{LangID}=$LangID;
      $exdb{Author}{PartNumber}=$PartNumber;
   }
   elsif($el eq "Id"){
      $Id=$currval;
   }
   elsif($el eq "Time"){
      $Time=str2time($currval);
   }
   elsif($el eq "HeartRateBpm"){
      $HeartRateBpm=$Value;
   }
   elsif($el eq "Value"){
      $Value=$currval;
   }
   elsif($el eq "Speed"){
      $Speed=$currval;
   }
   elsif($el eq "RunCadence"){
      $RunCadence=$currval;
   }
   elsif($el eq "DistanceMeters"){
      if($inTrack){
         $DistanceMeters=$currval;
      }
      else{
         $LapDistanceMeters=$currval;
      }
   }
   elsif($el eq "AltitudeMeters"){
      $AltitudeMeters=$currval;
   }
   elsif($el eq "TotalTimeSeconds"){
      $TotalTimeSeconds=$currval;
   }
}

#---------------------------------------------------------------------------
#main code starts here

#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
#load the initialisation file
my $cfgfile="$ENV{PLCFGFILE}";
if(-f $cfgfile){

   require $cfgfile;
}
else{

   die "cannot find $cfgfile";
}

#---------------------------------------------------------------------------
#get the cfg db
if(defined &get_cfgdb){
   $rcfgdb=get_cfgdb();
}
else{

   die "cannot get cfgdb";
}
#print Dumper(%$rcfgdb);
#print "$$rcfgdb{USER}{NAME}\n";
#print "premature\n";exit 1;

#---------------------------------------------------------------------------
#check environment
die "ID is not set" if(!$ENV{ID});
die "INFILE is not set" if(!$ENV{INFILE});
die "INFILEBASE is not set" if(!$ENV{INFILEBASE});


#---------------------------------------------------------------------------
my $mode="$ENV{ID}";

#---------------------------------------------------------------------------
#process tcx files
if($mode eq "fr310xt"){

   #------------------------------------------------------------------------
   parse_tcxfile();
   #gen_tcxfile();
   extrapolate_exdb();
   populate_hrmdb();

   #------------------------------------------------------------------------
   if(user_interaction()){
      gen_hrmfile();
   }

}

#---------------------------------------------------------------------------
#process fit files
elsif($mode eq "e500" or
      $mode eq "e800" or
      $mode eq "910xt" or
      1==2){

   #------------------------------------------------------------------------
   parse_fitcsvfile();

   #------------------------------------------------------------------------
   extrapolate_exdb();
   #smooth_exdb();
   populate_hrmdb();

   #------------------------------------------------------------------------
   if(user_interaction()){
      gen_hrmfile();
   }
}

#---------------------------------------------------------------------------
elsif($mode eq "tacx"){
   print "mode $mode not yet supported\n";
   print "input file: $ENV{INFILE}\n";
}
