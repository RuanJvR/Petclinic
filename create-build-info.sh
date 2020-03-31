#!/bin/bash

workspace=$1		# Comes from $BITBUCKET_REPO_OWNER
repository=$2		# Comes from $BITBUCKET_REPO_SLUG
buildNumber=$3		# Comes form $BITBUCKET_BUILD_NUMBER
commitHash=$4 		# Comes from $BITBUCKET_COMMIT
gitBranch=$5		# Comes from $BITBUCKET_BRANCH
gitOrigin=$6		# Comes from $BITBUCKET_GIT_HTTP_ORIGIN
buildUrl="https://bitbucket.org/$workspace/$repository/addon/pipelines/home#!/results/$buildNumber"

echo "Workspace: $workspace"
echo "Repository: $repository"
echo "BuildNumber: $buildNumber"
echo "CommitHash: $commitHash"
echo "GitBranch: $gitBranch"
echo "GitOrigin: $gitOrigin"
echo "BuildUrl: $buildUrl"

# Get Git commit info
if [ $buildNumber -eq 1 ]
	then
	echo "Getting commits for $commitHash"
	git log --pretty=oneline $commitHash > git-commits.log
else
	previousbuildNumber=$(expr $buildNumber - 1)
	baseURL="https://api.bitbucket.org/2.0/repositories/$workspace/$repository/pipelines"
	
	prevCommitHashURL="$baseURL/$previousbuildNumber"
	prevFullHash=$(curl -s -X GET "$prevCommitHashURL" | jq  '.target.commit.hash')
		
	prevHash="${prevFullHash%\"}"
	prevHash="${prevFullHash#\"}"
	commitHash="${commitHash%\"}"
	commitHash="${commitHash#\"}"
	
	prevHash=$(echo $prevHash | cut -b 1-7)
	commitHash=$(echo $commitHash | cut -b 1-7)

	echo "Comparing between $prevHash and $commitHash"
	git log --pretty=oneline "$prevHash"..$commitHash > git-commits.log
fi

echo "Building commit json"

# Create Commits Json
commits=''
counter=0
while read l; do
	hash=$(echo "$l" | cut -d' ' -f1)
	msg=$(echo "$l" | cut -d' ' -f 2-)
	linkUrl="$gitOrigin/commits/$hash"
	commit=$(jq -n \
		--arg id "$hash" \
		--arg url "$linkUrl" \
		--arg msg "$msg" \
		'{Id: $id, LinkUrl: $url, Comment: $msg}' \
		)
		
	if [ $counter -eq 0 ]
		then
		commits="$commit"
		else
		commits="$commits,$commit"
	fi
	counter=$(expr $counter + 1)
done < git-commits.log

# Delete temporary file
echo "Deleting temporary git-commits.log file"
rm git-commits.log

echo "Creating build info"
buildInfo=$(jq -n \
		--arg be "BitBucket" \
		--arg br "$gitBranch" \
		--arg bn "$buildNumber" \
		--arg bu "$buildUrl" \
		--arg vcs "Git" \
		--arg vcr "$gitOrigin" \
		--arg vcn "$commitHash" \
		--argjson cmt "[$commits]" \
		'{BuildEnvironment: $be, Branch: $br, BuildNumber: $bn, BuildUrl: $bu, VcsType: $vcs, VcsRoot: $vcr, VcsCommitNumber: $vcn, Commits: $cmt}' \
		)		
echo "Writing out octopus.buildinfo file"
echo $buildInfo > octopus.buildinfo