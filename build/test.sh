#!/usr/bin/env bash
#
# Script to test the container image
#
# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0
#
# Usage: test.sh <majorver> [url] [curl-command]
# Example: ./build/test.sh 3 "http://0.0.0.0:$(DEVPORT)" "$(CONTAINER_ENGINE) exec -t $(IMGBASENAME) curl"
# The curl command arg allows us to run curl within the container rather than
# from the build server if required, which seems to be necessary when building
# in Jenkins & Docker-in-Docker (can't connect to container from agent).


# set -x
rc=0
majorver=${1:-3}
baseurl="${2:-http://127.0.0.1:8080}"
curl="${3:-curl}"

# Wait for container to be ready
max=10
sleep=1
cnt=0
ok=0
while [ $cnt -lt $max ]
do
	sleep $sleep
	(( cnt = cnt + 1 ))
	$curl --silent --head "${baseurl}/healthz.json" | sed -e 's/\r//g' | grep -q -w 200
	if [ $? -eq 0 ]
	then
		ok=1
		break
	else
		echo "WARNING: Container not ready - try $cnt"
	fi
done
if [ $ok -ne 1 ]
then
	echo "ERROR: Container not ready"
	(( rc = rc + 1 ))
else
	echo "OK: Container ready"

	# Test the container image
	ver=$(bash $(dirname $0)/getver patch ${majorver})
	jsonver=$($curl --silent "${baseurl}/index.json" | sed -e 's/\r//g' | jq '.image_info.image_version' -r)
	if [ "$ver" != "$jsonver" ]
	then
		echo "ERROR: Expected version [$ver], got JSON version [$jsonver]"
		(( rc = rc + 1 ))
	else
		echo "OK: JSON version ${jsonver}"
	fi

	# The sed filter is necessary to remove CR characters added by "docker run"
	textver=$($curl --silent "${baseurl}/index.txt" | sed -e 's/\r//g' | awk 'BEGIN {FS=":"} {if ($1 == "image_version") {print $2}}')
	if [ "$ver" != "$textver" ]
	then
		echo "ERROR: Expected version [$ver], got text version [$textver]"
		(( rc = rc + 1 ))
	else
		echo "OK: Text version ${textver}"
	fi

	# CR/LF terminated output
	csvver=$($curl --silent "${baseurl}/index.csv" | sed -e 's/\r//g' | awk 'BEGIN {FS=","} {if ($1 == "\"image_version\"") {print $2}}' | sed -e 's/"//g')
	if [ "$ver" != "$csvver" ]
	then
		echo "ERROR: Expected version [$ver], got CSV version [$csvver]"
		(( rc = rc + 1 ))
	else
		echo "OK: CSV version ${csvver}"
	fi
fi

exit $rc
