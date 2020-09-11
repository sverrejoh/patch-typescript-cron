#!/bin/bash

pushd $(dirname $0)

typescript_checkout="checkouts/typescript.git"
patch_file="`pwd`/patches/0001-resolution-platform-option-env-with-dts-fix.patch"

if [ ! -d "$typescript_checkout" ]; then
    git clone --quiet https://github.com/microsoft/TypeScript $typescript_checkout
fi

pushd $typescript_checkout

# Make sure everything is clean and nice.
git fetch --quiet origin

# Find the latest tag
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))

echo "Found latest tag: $latest_tag"

# Define a branch for our work
tag_branch="svjohan/generated-typescript-platform-resolution/$latest_tag"

# Check if the branch for the tag exists, and exit if so.
branch_list=$(git branch --list $tag_branch)
if [ -n "$branch_list" ]
then
    echo "Branch ${tag_branch} exists in TypeScript"
    exit 1
fi

# Create the branch
# git checkout -b $tag_branch $latest_tag
git worktree add ../../worktree/$latest_tag $latest_tag

cd ../../worktree/$latest_tag

# Apply the patch
git apply $patch_file

# Exit if the patch failed
patch_status=$?
if test $patch_status -eq 1
then
    echo "Patch didn't apply. Please fix and try again"
    exit 1
fi

git commit -a -m "Add resolutionPlatforms option/env for better React Native support (with .d.ts fix)"

# Update name.
sed -i -E "s/\"name\": \"typescript\"/\"name\": \"@msfast\/typescript-platform-resolution\"/" package.json
git commit -a -m "Update name to @msfast/typescript-platform-resolution"

# Keep the npm version number for later
typescript_version=$(grep "\"version\":" package.json | awk 'BEGIN{FS="\""}{print $4}')

# Build and commit artifacts.
npm install || exit 1
npm run jake LKG || exit 1
git add .
git commit -m "Update LKG"

# Ready to publish. This could be automated, but it's nice with a
# human overlook first.
echo "Ready to publish TypeScript $typescript_version" | mail -s "TypeScript $typescript_version" "svjohan@microsoft.com"

popd

# Skipping the midgard upgrade
exit 0

midgard_checkout="midgard.git"

if [ ! -d "$midgard_checkout" ]; then
    git clone msfast@vs-ssh.visualstudio.com:v3/msfast/FAST/Midgard $midgard_checkout
fi

pushd $midgard_checkout

# Make sure everything is clean and nice.
git fetch origin
git reset --hard origin/master
git clean -xdf

# Check if the branch for the tag exists, and exit if so.
branch_list=$(git branch --list $tag_branch)
if [ -n "$branch_list" ]
then
    echo "Branch ${tag_branch} exists in Midgard"
    exit 1
fi

git checkout -b $tag_branch origin/master

find . -name package.json | xargs sed -i '' -E "s/npm:@msfast\/typescript-platform-resolution@[^\"]+/npm:@msfast\/typescript-platform-resolution@$typescript_version/"
git commit -a -m "Updated TypeScript to $latest_tag"
better-vsts-npm-auth
MIDGARD_SCOPE="all" yarn;
yarn build

popd # Midgard

popd # Script directory
