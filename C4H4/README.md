# Computation of singlet-triplet gap of cyclobutadiene

* Clone the repository 
```	
	git clone https://github.com/michalhapka/trex_workshop2023.git
```
In ``trex_workshop2023/C4H4`` directories you will find all files needed to run ACn calculations with GammCor for singlet (S) and triplet (T) states using CAS(2,2) and CAS(4,4) reference wavefunctions.

* Input files for GammCor with electron integrals and 1,2-reduced density matrices have been generated with Dalton and are provided. If you want to learn how to use Dalton interfaced with GammCor see example in GammCor user manual: [link](https://qchem.gitlab.io/gammcor-manual/pages/calculation/correlation_methods/acn_dalton.html)

* Run GammCor calculations using files in ``CAS22/S, CAS22/T, CAS44/S, CAS44/T`` directories.  
For that prepare the ``run.sh`` script (provide the correct path to gammcor in ``GAMMCOR_EXEC="...."``)
```
#!/bin/bash

GAMMCOR_EXEC="...."

$DALTON_EXEC -noarch -t . -get "AOTWOINT AOONEINT SIRIFC SIRIUS.RST rdm2.dat " $1  > aaa

mv $1.AOONEINT   AOONEINT
mv $1.AOTWOINT   AOTWOINT
mv $1.SIRIFC     SIRIFC
mv $1.SIRIUS.RST SIRIUS.RST
mv $1.rdm2.dat   rdm2.dat

rm -rf DALTON_scratch* aaa

export MKL_NUM_THREADS=1

$GAMMCOR_EXEC > "gammcor.out"
```

and the slurm scirpt ``job1`` 

```
#!/bin/bash
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --nodelist=cn08
#SBATCH -t 1:00:00
#SBATCH --mem=20GB
srun ./run.sh c4h4
```

Copy scripts to ``CAS22/S, CAS22/T, CAS44/S, CAS44/T`` directories. 
In each directory submit the job
```
sbatch job1
```

* Collect the results from gammcor.out files, look for the line `` ECASSCF+ENuc, ACn-Corr, ACn-CASSCF `` at the end of outputs.

* Compute S-T energy gaps for CASSCF (``ECASSCF+ENuc``) and ACn-CASSCF (``ACn-CASSCF``) from CAS(2,2) and CAS(4,4) models. Compare the numbers with the reference value of 0.18 eV from Stoneburner et al., J. Chem. Phys. 2017, 147, 164120.


