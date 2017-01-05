#!/bin/sh -e

# Snapshots and sends backups of subvolumes from the top-level of a btrfs filesystem to the default subvolume of another btrfs filesystem.
# Can send standalone or incremental backups of subvolumes. Initialize the first backup in an incremental series with the commands:
# btrfs subvolume snapshot -r /mnt/toplevel/subvolume/ /mnt/toplevel/backup/#snapshot-20170101
# btrfs send /mnt/toplevel/backup/#snapshot-20170101/ | btrfs receive /mnt/backup/

TOPLEVELMOUNTPOINT="/mnt/toplevel"
SNAPSHOTSDIRECTORY="backup"
BACKUPMOUNTPOINT="/mnt/backup"

ISOLATEDSUBVOLS="isolated1 isolated2"
INCREMENTALSUBVOLS="incremental1 incremental2"

### Configuration section ends

fail ()
{
    printf "$1" 1>&2
    exit 1
}

command -v mount >/dev/null 2>&1 || fail "Couldn't locate mount command"
command -v btrfs >/dev/null 2>&1 || fail "Couldn't locate btrfs command"

DATESTAMP=$(date +'%Y%m%d')

[ -d "${TOPLEVELMOUNTPOINT}" ] || fail "Top-level subvolume mount point doesn't exist: ${TOPLEVELMOUNTPOINT}"
mount "${TOPLEVELMOUNTPOINT}" || fail "Couldn't mount top-level subvolume: ${TOPLEVELMOUNTPOINT}"
[ -d "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}" ] || fail "Snapshot target directory doesn't exist: ${TOPLEVELMOUNTPOINT}/backup"

for subvolume in ${ISOLATEDSUBVOLS} ${INCREMENTALSUBVOLS}
do
	[ -d "${TOPLEVELMOUNTPOINT}"/"${subvolume}" ] || fail "Subvolume to snapshot doesn't exist: ${TOPLEVELMOUNTPOINT}/${subvolume}"
	[ -d "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}"/"#${subvolume}-${DATESTAMP}" ] && fail "Snapshot already exists: ${TOPLEVELMOUNTPOINT}/${SNAPSHOTSDIRECTORY}/#${subvolume}-${DATESTAMP}"
	btrfs subvolume snapshot -r "${TOPLEVELMOUNTPOINT}"/"${subvolume}" "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}"/"#${subvolume}-${DATESTAMP}"
done

[ -d "${BACKUPMOUNTPOINT}" ] || fail "Backup subvolume mount point doesn't exist: ${BACKUPMOUNTPOINT}"
mount "${BACKUPMOUNTPOINT}" || fail "Couldn't mount backup subvolume: ${BACKUPMOUNTPOINT}"

for subvolume in ${ISOLATEDSUBVOLS}
do
	time btrfs send "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}"/"#${subvolume}-${DATESTAMP}" | btrfs receive "${BACKUPMOUNTPOINT}"
done

for subvolume in ${INCREMENTALSUBVOLS}
do
	parent=$(basename $(ls -dt "${BACKUPMOUNTPOINT}"/"#${subvolume}-"*/ | head -n1))
	[ -d "${BACKUPMOUNTPOINT}"/"${parent}" ] || fail "Couldn't find parent subvolume on backup subvolume for snapshot: ${TOPLEVELMOUNTPOINT}/${SNAPSHOTSDIRECTORY}/#${subvolume}-${DATESTAMP}"
	[ -d "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}"/"${parent}" ] || fail "Couldn't find parent subvolume on top-level subvolume for snapshot: ${TOPLEVELMOUNTPOINT}/${SNAPSHOTSDIRECTORY}/#${subvolume}-${DATESTAMP}"
	time btrfs send -p "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}"/"${parent}" "${TOPLEVELMOUNTPOINT}"/"${SNAPSHOTSDIRECTORY}"/"#${subvolume}-${DATESTAMP}" | btrfs receive "${BACKUPMOUNTPOINT}"
done

umount "${BACKUPMOUNTPOINT}" || fail "Couldn't unmount backup subvolume: ${BACKUPMOUNTPOINT}"
umount "${TOPLEVELMOUNTPOINT}" || fail "Couldn't unmount top-level subvolume: ${TOPLEVELMOUNTPOINT}"
