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

if [ -v args[backup] ]; then

	bash -c "cd $mp && $RESTIC backup . $RESTIC_ARGS -H pve --exclude-caches ${excludes}"
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
