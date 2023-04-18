#!/bin/bash

# ************ How to use this script ********
#  bash <path_to_dalton_executable> <path_to_gammcor_executable> 

DALTON_EXEC=$1
GAMMCOR_EXEC=$2

#DALTON_EXEC="$HOME/Programs/dalton/build_intel/dalton"
#GAMMCOR_EXEC="$HOME/Programs/gammcor/build_IntCholesky/gammcor"

# ***********  Aim of the scipt is twofold ***
# 1) RUN DALTON  : CASSCF
# 2) RUN GAMMCOR : SAPT

# preliminaries

function grepper {
local output=$1
local dist=$2

 elst=$(grep "Eelst"        $output | awk '{print $3}')
 e1ex=$(grep "E1exch(S2)"   $output | awk '{print $3}')
 e2ind=$(grep "E2ind "      $output | tail -1 | awk '{print $3}')
 e2disp=$(grep "E2disp "    $output | tail -1 | awk '{print $3}')
 e2xi=$(grep "E2exch-ind"   $output | tail -1 | awk '{print $3}')
 e2xd=$(grep "E2exch-disp " $output | tail -1 | awk '{print $3}')
 etot=$(grep "Eint(SAPT"    $output | awk '{print $3}')

 echo $dist,$elst,$e1ex,$e2ind,$e2xi,$e2disp,$e2xd,$etot >> res.dat

}

if [ -z $1 ] ; then
  echo "Error! Please specify path to Dalton executable as the first arg"
  exit 1
fi

# end preliminaries

export OMP_NUM_THREADS=1

mkdir -p MONOMER_A
mkdir -p MONOMER_B

### CALCULATION STARTS HERE
# ****************************************

for i in 1.44 7.20 ; do

   cp $i'_A.mol'  MONOMER_A/run.mol
   cp $i'_A.dal'  MONOMER_A/run.dal

   cd MONOMER_A
   $DALTON_EXEC -noarch -mb 100 -get "AOTWOINT AOONEINT SIRIFC SIRIUS.RST rdm2.dat " run  > skas

   cd ..

   cp $i'_B.mol'  MONOMER_B/run.mol
   cp $i'_B.dal'  MONOMER_B/run.dal

   cd MONOMER_B
   $DALTON_EXEC -noarch -mb 100 -get "AOONEINT AMFI_SYMINFO.TXT SIRIFC SIRIUS.RST rdm2.dat " run  > skas

   cd ..

   #MONOMER A
   mv MONOMER_A/run.AOONEINT    AOONEINT_A
   mv MONOMER_A/run.AOTWOINT    AOTWOINT_A
   mv MONOMER_A/run.SIRIFC      SIRIFC_A
   mv MONOMER_A/run.SIRIUS.RST  SIRIUS_A.RST
   mv MONOMER_A/run.rdm2.dat    rdm2_A.dat

   #MONOMER_B
   mv MONOMER_B/run.AOONEINT       AOONEINT_B
   mv MONOMER_B/run.SIRIFC         SIRIFC_B
   mv MONOMER_B/run.SIRIUS.RST     SIRIUS_B.RST
   mv MONOMER_B/run.rdm2.dat       rdm2_B.dat 
   mv MONOMER_B/run.AMFI_SYMINFO*  SYMINFO_B

   # run GammCor
   $GAMMCOR_EXEC > "gammcor_$i.out"
   grepper "gammcor_$i.out"

done
