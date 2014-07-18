#!/bin/bash


source $WORKINGDIR/.settings

export BINDIR=$(cd $(dirname $0);pwd)
export BASEDIR=$(cd $BINDIR/..;pwd)
export BASENAME=$(echo $(basename $0)|sed "s/\..*//")
export PLCFGFILE=$BINDIR/$BASENAME-ini.pl

export PLFILE=$BINDIR/$BASENAME.pl
export LOGDIR=$BASEDIR/log
export OUTDIR=$BASEDIR/tmp
export FITCSVDIR=$BASEDIR/tmp/fitcsv
FITCSVTOOL=../../bin/FitCSVTool.jar
export HRMFILEOUTPUT=$OUTDIR/gen-0.hrm
export TCXFILEOUTPUT=$OUTDIR/gen-0.tcx

L=------------------------------------------------------------------------

#---------------------------------------------------------------------------
#unpack the fit file into csv files for the perl script to pick up
#---------------------------------------------------------------------------
unpack_fit_file(){
   rm -rf $FITCSVDIR
   mkdir -p $FITCSVDIR
   cd $FITCSVDIR
   echo decoding fit file...
   java -jar $FITCSVTOOL -b $1 $(basename $1)
}


#---------------------------------------------------------------------------
#check that all files are there
for F in $PLCFGFILE $PLFILE; do
   if [ ! -f $F ]; then
      echo error - cannot find $F
      exit 1
   fi
done


#---------------------------------------------------------------------------
#check output directory
if [ -z "$POLARDIR" ]; then
   echo "error - POLARDIR not set"
   exit 1
else
   if [ ! -d "$POLARDIR" ]; then
      echo "error - POLARDIR=$POLARDIR does not exist"
      exit 1
   fi
fi

echo $L
if [ -d $DLDIR ]; then
   #---------------------------------------------------------------------

   for INFILE in $(find $DLDIR -type f -prune -iname "$PATTERN" -mtime -6h); do
      echo file: $(basename $INFILE)
      unpack_fit_file $INFILE
      export INFILE
      export INFILEBASE=$(basename $INFILE)
      perl $PLFILE
   done

else
   echo warning - cannot find $DLDIR
fi
