#------------------------------------------------------------------------
my %cfgdb;

#------------------------------------------------------------------------
$cfgdb{USER}{NAME}="Brandon Murry";
@{$cfgdb{USER}{HRZONES}}=([190],[171],[152],[133],[114],[95],[76],[57],[38],[19],[0]);
@{$cfgdb{USER}{TRIP}}=([0],[0],[0],[0],[0],[0],[0],[0]);
#print Dumper(%cfgdb);
#print "premature\n"; exit 1;

#------------------------------------------------------------------------
sub get_cfgdb{\%cfgdb;}

#------------------------------------------------------------------------
1;
