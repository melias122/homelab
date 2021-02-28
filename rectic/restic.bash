#!/bin/bash
set -e

# My restic repo (local) and password
export RESTIC_REPOSITORY="/backup"
export RESTIC_PASSWORD=""

# Backbalze B2
export B2_ACCOUNT_ID=""
export B2_ACCOUNT_KEY=""

# restic command path
RESTIC="restic"

# maybe some default args such as '-v'
RESTIC_ARGS=""

# B2 repo (not a part of restic env)
B2_RESTIC_REPOSITORY=""

REST_RESTIC_REPOSITORY="rest:http://restic.homelab.sk:8000"

# snapshot prefix and timestamp
snapID="backup-$(date +"%Y%m%d-%H%M%S")"

# mount point prefix
# mp="/mnt/${snapID}"
mp="/mnt/backup"

# pools to backup e.g. "pool0 pool1"
pools="pool"

excludes=(
	".DS_Store"
	".recycle"
	".windows"
	".Trashes"

	".ssh"
	".gnupg"
	".password-store"

	"Downloads"

	"tvheadend/epgdb.v3"
	"tvheadend/imagecache"
	"unifi/config"
	"!unifi/config/backup"
)

B2Excludes=(

	"Music"
	"Movies"
	"Videos"

	"hudba"
	"Hudba"
	"timemachine"
)

declare -A args

# parse args
for arg in $@; do
	case $arg in
		--b2 )
			export RESTIC_REPOSITORY=$B2_RESTIC_REPOSITORY
			excludes+=(${B2Excludes[@]})
			;;
		--backup )
			args[backup]=true ;;
		--rest )
			export RESTIC_REPOSITORY=$REST_RESTIC_REPOSITORY ;;
		--forget )
			args[forget]=true ;;
		--check )
			args[check]=true ;;
		* )
			RESTIC_ARGS+="$arg " ;;
	esac
done

#
# run restic command and exit
#
if [ ${#args[@]} = 0 ]; then
    $RESTIC $RESTIC_ARGS
    exit 0
fi

# build excludes
excludes="$(echo ${excludes[@]} | xargs printf -- "-e %s ")"

createSnapMount () {
    for pool in $pools; do

	# create recursive snapshot of dataset
	zfs snapshot -r "${pool}@${snapID}"

	# mk mount point
	mkdir -p "${mp}/${pool}"

	# mount datasets under /mnt, e.g. /mnt/dataset0, /mnt/dataset1
	for dataset in $(zfs list -t filesystem -H -o name -r ${pool}); do
	    mount -t zfs "${dataset}@${snapID}" "${mp}/${dataset}"
	done

	# mount zvols under /mnt, e.g. /mnt/volume0, /mnt/volume1
	# for volume in $(zfs list -t volume -H -o name -r ${pool}); do
	# zfs clone "${volume}@${snapID}" "${volume}-${snapID}"
	# mkdir "${mp}/$(basename $volume)"
	# while [ ! -b "/dev/zvol/${volume}-${snapID}" ]; do sleep 1; done
	# mount "/dev/zvol/${volume}-${snapID}" "${mp}/$(basename $volume)"
	# done

    done
}

removeSnapMount () {

    # umount zvols and destroy clones
    # for volume in $(zfs list -H -o name -t volume | grep "\-${snapID}"); do
    # zfs destroy "${volume}-${snapID}"
    # done

    for pool in $(zfs list -H -o name -t snapshot $pools | grep $snapID | cut -d'@' -f1); do
	umount -R "${mp}/${pool}"

	# destroy snapshots recursively
	zfs destroy -r "${pool}@${snapID}"
    done

    rm -fr "${mp}"
}

if [ -v args[backup] ]; then

    	# make sure we cleanup snapshots, mount points, and created dirs
	trap removeSnapMount EXIT

	# create snapshot of $zpools and mount them under $mp
	createSnapMount

	bash -c "cd $mp && $RESTIC backup . $RESTIC_ARGS -H pve --exclude-caches ${excludes}"

	# cleanup
	removeSnapMount
fi

if [ -v args[forget] ]; then
	# forget old snapshots
	$RESTIC forget $RESTIC_ARGS --keep-daily=14 --keep-weekly=12 --keep-monthly=12 --keep-yearly=100 --prune
fi

if [ -v args[check] ]; then
	# check backup repository
	[ "$RESTIC_REPOSITORY" = "$B2_RESTIC_REPOSITORY" ] && RESTIC_ARGS="$RESTIC_ARGS --with-cache"
	$RESTIC check $RESTIC_ARGS
fi
