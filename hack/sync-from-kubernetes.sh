#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script is to be used in the interim to pull any new commits relevant to federation in k8s.io/kubernetes.
# It takes direct inspiration from https://github.com/kubernetes/apimachinery/blob/master/hack/sync-from-kubernetes.sh

set -o errexit
set -o nounset
set -o pipefail

ROOTDIR=$(dirname "${BASH_SOURCE}")/..
k8sRepoPath=${K8S_REPO_PATH:-"https://github.com/kubernetes/kubernetes"}
commitDir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

git remote add upstream-k8s ${k8sRepoPath}  || true
git fetch upstream-k8s

currentBranch=$(git rev-parse --abbrev-ref HEAD)
lastKubeSHA=$(cat ${ROOTDIR}/hack/git-hashes/last-kube-sha)
echo ${lastKubeSHA}
lastFedSHA=$(cat ${ROOTDIR}/hack/git-hashes/last-fed-sha)
echo ${lastFedSHA}

git branch -D kube-sync || true
git checkout upstream-k8s/master -b kube-sync
git reset --hard upstream-k8s/master
newKubeSHA=$(git log --oneline --format='%H' kube-sync -1)

# this command rewrites git history to *only* include federation
# use --subdirectory filter once https://github.com/kubernetes/kubernetes/pull/52667 is merged
# --subdirectory-filter has huge huge time advantage over --index-filter
# git filter-branch -f --subdirectory-filter federation HEAD
git filter-branch -f --index-filter 'git rm --cached -qr --ignore-unmatch -- . && git reset -q $GIT_COMMIT -- federation test/integration/federation test/e2e_federation' --prune-empty HEAD

# strip unwanted empty commits
git filter-branch -f --prune-empty --parent-filter \
    'sed "s/-p //g" | xargs -r git show-branch --independent | sed "s/\</-p /g"'

# store SHAs for next sync
newFedSHA=$(git log --oneline --format='%H' kube-sync -1)
git log --no-merges --format='%H' --reverse ${lastFedSHA}..HEAD > ${commitDir}/commits

git checkout ${currentBranch}

while read commitSHA; do
	echo "working ${commitSHA}"
	git cherry-pick ${commitSHA}
done <${commitDir}/commits

# keep the k8s.io/kubernetes commitSHA and federation commitSHA for the next sync
echo ${newKubeSHA} > ${ROOTDIR}/hack/git-hashes/last-kube-sha
echo ${newFedSHA} > ${ROOTDIR}/hack/git-hashes/last-fed-sha
git commit -m "sync(k8s.io/kubernetes): ${newKubeSHA}" -- ${ROOTDIR}/hack/last-kube-sha ${ROOTDIR}/hack/last-fed-sha
rm -r ${commitDir}
