#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Test the container image
# set -x

ver=$(cat .version)
jsonver=$(curl --silent http://127.0.0.1:8080/index.json | jq '.image_version' -r)
textver=$(curl --silent http://127.0.0.1:8080/index.txt | awk 'BEGIN {FS=":"} {if ($1 == "image_version") {print $2}}')
csvver=$(curl --silent http://127.0.0.1:8080/index.csv | awk 'BEGIN {FS=","} {if ($1 == "\"image_version\"") {print $2}}' | sed -e 's/"//g' -e 's/\r//')

rc=0
if [ "$ver" != "$jsonver" ]
then
	echo "ERROR: expected version [$ver], got JSON version [$jsonver]"
	(( rc = rc + 1 ))
else
	echo "OK: JSON version"
fi

if [ "$ver" != "$textver" ]
then
	echo "ERROR: expected version [$ver], got text version [$textver]"
	(( rc = rc + 1 ))
else
	echo "OK: text version"
fi

if [ "$ver" != "$csvver" ]
then
	echo "ERROR: expected version [$ver], got CSV version [$csvver]"
	(( rc = rc + 1 ))
else
	echo "OK: csv version"
fi

exit $rc
