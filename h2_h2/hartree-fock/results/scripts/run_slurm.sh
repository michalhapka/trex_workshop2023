#!/bin/bash
#SBATCH -n 1
#SBATCH -t 00:10:00
#SBATCH --mem=2GB
#SBATCH --nodelist=cn08

###### how to use this script #######
# sbatch run.sh <path_to_quantum_package.rc> <path_to_gammcor_executable>

##### INPUT PARAMS  ###########

QP_RC=$1
GAMMCOR_EXEC=$2

BASIS=aug-cc-pvdz

#QP_RC="/home/michalhapka/qp2"
#GAMMCOR_EXEC="/home/michalhapka/pr-dmft/gammcor"

##### END INPUT PARAMS  #######

if [ -z $1 ] ; then
  echo "Error! Please specify path to quantum_package.rc file as the 1st arg"
  exit 1
fi
if [ -z $2 ] ; then
  echo "Error! Please specify path to GammCor executable as the 2nd arg"
  exit 1
fi

cwd=$(srun echo $PWD)
mkdir -p /tmp/$$
cd /tmp/$$

source $QP_RC/quantum_package.rc

export OMP_NUM_THREADS=4

###### define functions ###########

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

function input_gammcor {
local dist=$1

cat << EOF > input.inp

Calculation
 JobTitle   H2-H2 $i (QPACKAGE)
 Interface  TREXIO
 JobType    SAPT
 RDMType    CI
 TwoMoInt   FOFO
 IPrint     11
end

System
 Monomer       A
 NAtoms        2
 ZNucl         2
 TrexFile      A.h5
End

System
 Monomer       B
 NAtoms        2
 ZNucl         2
 TrexFile      B.h5
End

EOF

}

function input_geom {
local dist=$1
local output=$2

dist=$(echo "$dist * 1.44 - 0.72006119069" | bc -l )

cat << EOF > $output
4
! bohr
H   0.00000000   0.0000000000    $dist
H   0.00000000   0.0000000000   -0.72006119069
H   0.00000000   0.72006119069  -6.93000000000
H   0.00000000  -0.72006119069  -6.93000000000
EOF

}

###### end functions ###########

# main loop
for i in 1.0 5.0 ; do

   for m in "A" "B" ; do

      # set-up geometry
      input_geom $i h2_h2_$i.xyz

      # Create initial EZFIO database
      qp create_ezfio -a -b $BASIS h2_h2_$i.xyz -o $m'_'$i

      qp set_file $m'_'$i

      qp set electrons elec_alpha_num 1
      qp set electrons elec_beta_num  1

      # set ghost atoms
      if [ $m == "A" ] ; then
         qp set nuclei nucl_label  "['H', 'H', 'x', 'x']"
         qp set nuclei nucl_charge "[1.0, 1.0, 0.0, 0.0]"
      elif [ $m == "B" ] ; then
         qp set nuclei nucl_label  "['x', 'x', 'H', 'H']"
         qp set nuclei nucl_charge "[0.0, 0.0, 1.0, 1.0]"
      fi

      # Run SCF
      qp run scf  >  $m'_'$i'.out'

      # Export HDF5 files for GammCor
      qp set gammcor_plugin cholesky_tolerance 1.e-5
      qp set gammcor_plugin trexio_file \"$m.h5\"
      qp run export_gammcor >> 'export_'$m'.out'
      qp run gammcor_plugin >> 'export_'$m'.out'

      ## backup #1
      mkdir -p $cwd/results
      mkdir -p $cwd/results/$i
      mv $m'_'$i'.out'     $cwd/results/$i
      mv $m'_'$i'.out'     $cwd/results/$i
      mv 'export_'$m'.out' $cwd/results/$i

   done # end QP2

   export OMP_NUM_THREADS=1

   # run GammCor
   input_gammcor $i
   $GAMMCOR_EXEC > 'gammcor_'$i'.out'
   grepper "gammcor_"$i".out" $i

   ## backup #2
   mv "gammcor_"$i".out" $cwd/results/$i
   mv A.h5  $cwd/results/$i
   mv B.h5  $cwd/results/$i

done

# remove scratch
rm -r /tmp/$$

