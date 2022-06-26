#!/usr/bin/env bash

# Example: makeWorkspaceForPackage.sh -c ~/.cache/roa/repos -p RebuildOfArchangelinux/RoAPkgBuilds tmsu-git tmsu-git

RepoCacheRootDir="$HOME/.cache/RoA/Repos"
RoAPkgBuildsDir=""
PackageName=""
TargetDir=""

while getopts "c:p:" value; do
    case "${value}" in
        c)
            RepoCacheRootDir=${OPTARG}
            ;;
        p)
            RoAPkgBuildsDir=${OPTARG}
            ;;
        *)
            echo "Unknown params"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

PackageName="$1"
TargetDir="$2"

if [ -z "$RepoCacheRootDir" ] || [ -z "$RoAPkgBuildsDir" ] || [ -z "$PackageName" ] || [ -z "$TargetDir" ]; then
    echo "Incomplete params"
    exit 1
fi



echo "Creating workspace for RoA package \"$PackageName\" @ $TargetDir ..."

# Get repo source
roaPackageDir=$RoAPkgBuildsDir/$PackageName
sourceURL=$(cat $roaPackageDir/Source)
repoCacheDir=$RepoCacheRootDir/$(echo $sourceURL | sed "s/^https:\/\///")
if [ ! -d $repoCacheDir ]
then
    mkdir -p $RepoCacheRootDir
    echo "Cloning $sourceURL to $repoCacheDir ..."
    git clone $sourceURL $repoCacheDir
else
    echo "Using cached repo at $repoCacheDir ..."
fi

# Initialize target directory and git repo
cachedPkgBuildDir="$repoCacheDir/$(cat $roaPackageDir/Subfolder)"
echo "Copying cache $cachedPkgBuildDir to workspace $TargetDir ..."
cp -R $cachedPkgBuildDir/. $TargetDir
# rm -rf $TargetDir/.git
# TODO: Extract history of TargetDir
# TODO: Ensure TargetDir is empty
echo "Initializing git repo ..."
git -C $TargetDir init
git -C $TargetDir add --all
git -C $TargetDir commit -m "Initial commit."

# Apply the patches
for patchFile in $roaPackageDir/Patch-*; do
    patchFileBasename=$(basename $patchFile)
    echo "Applying patch $patchFileBasename ..."
    patch -d $TargetDir -p1 < $patchFile
    git -C $TargetDir add --all
    git -C $TargetDir commit -m "[RoA] Applying $patchFileBaseName"
done
