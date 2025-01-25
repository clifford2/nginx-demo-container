# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: BSD-2-Clause

:
baseurl='http://0.0.0.0:8080/'
tries=100

count=0
for type in html json csv txt
do
	while [ $count -lt $tries ]
	do
		curl --silent ${baseurl}index.${type} > /dev/null
		(( count = count + 1 ))
		echo $count
	done
done
