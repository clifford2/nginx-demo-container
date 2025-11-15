#!/usr/bin/env bash
#
# Script to test the container image
#
# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

# set -x
rc=0
baseurl="${1:-http://127.0.0.1:8080}"

# Wait for container to be ready
max=3
sleep=1
cnt=0
ok=0
while [ $cnt -lt $max ]
do
	sleep $sleep
	(( cnt = cnt + 1 ))
	curl --silent --head "${baseurl}/healthz.json" | grep -q -w 200
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
	ver=$(cat .version)
	jsonver=$(curl --silent "${baseurl}/index.json" | jq '.image_version' -r)
	if [ "$ver" != "$jsonver" ]
	then
		echo "ERROR: Expected version [$ver], got JSON version [$jsonver]"
		(( rc = rc + 1 ))
	else
		echo "OK: JSON version"
	fi

	textver=$(curl --silent "${baseurl}/index.txt" | awk 'BEGIN {FS=":"} {if ($1 == "image_version") {print $2}}')
	if [ "$ver" != "$textver" ]
	then
		echo "ERROR: Expected version [$ver], got text version [$textver]"
		(( rc = rc + 1 ))
	else
		echo "OK: Text version"
	fi

	csvver=$(curl --silent "${baseurl}/index.csv" | awk 'BEGIN {FS=","} {if ($1 == "\"image_version\"") {print $2}}' | sed -e 's/"//g' -e 's/\r//')
	if [ "$ver" != "$csvver" ]
	then
		echo "ERROR: Expected version [$ver], got CSV version [$csvver]"
		(( rc = rc + 1 ))
	else
		echo "OK: Csv version"
	fi
fi

exit $rc
