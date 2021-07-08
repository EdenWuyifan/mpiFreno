source ~/mpiFreno/config.sh

PERFDBDIR=$performance
if [ ! -d $PERFDBDIR ]; then
	mkdir $PERFDBDIR
fi
for SLURM_ARRAY_TASK_ID in 11 21 31 41 51
do

	if [ $target == "result" ];
	then
		mpiexec -np $partition python3 $runresult --dbpath $ALLDATADIR -d $dataset -m $SLURM_ARRAY_TASK_ID -r $RESULTDIR
	else
		if [ $target == "tablesize" ];
		then
				# if table size experiment runs any number of times and all the hosts output to the same file
				# TODO
				# if table size experiment runs once and one output file per host
				# mpiexec -np 9 python3 $runsize -e $expnum --dbpath $ALLDATADIR -d $dataset -m $SLURM_ARRAY_TASK_ID -s $SIZEDIR
				# if table size experiment runs $expnums times and one output file per host
				for expnum in $(seq 1 1 $expnums);
				do
					THISSIZEDIR=$SIZEDIR/$expnum
					if [ ! -d $THISSIZEDIR ]; then
						mkdir $THISSIZEDIR
					fi
					mpiexec -np $partition python3 runsize.py --dbpath $ALLDATADIR -d $dataset -m $SLURM_ARRAY_TASK_ID -s $THISSIZEDIR
				done
		else
			for expnum in $(seq 1 1 $expnums);
			do
				for interval in 0 20000 40000 60000 80000 100000
				do
					for partition in 4 8 12
					do
						PERFDIR="$PERFDBDIR/$partition"
						if [ ! -d $PERFDIR ]; then
							mkdir $PERFDIR
						fi
						#performance/db/partition/MINSUP_interval.txt
						PERFFILE="$PERFDIR/$SLURM_ARRAY_TASK_ID"_"$interval.txt"
						if [ ! -f $PERFFILE ]; then
							touch $PERFFILE
						fi
						(time -p mpirun -np $(($partition+1)) $runperf \
						--dbpath $ALLDATADIR -d $dataset \
						-m $SLURM_ARRAY_TASK_ID \
						-p $partition -i $interval) \
						>> $PERFFILE 2>&1
					done
				done
			done
		fi
	fi
done
