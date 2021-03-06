#!/bin/sh
#This file is part of The Open GApps script of @mfonville.
#
#    The Open GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
TOP="$(realpath .)"
SOURCES="$TOP/sources"

command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command

argument(){
	case $1 in
		all) apparchs="$apparchs"" all";;
		arm) apparchs="$apparchs"" arm";;
		arm64) apparchs="$apparchs"" arm64";;
		x86) apparchs="$apparchs"" x86";;
		x86_64) apparchs="$apparchs"" x86_64";;
		*) maxsdk="$1";;
	esac
}

echo "=== Simple How To ===:
* No arguments: Show all packages of all architectures and SDK levels
* A SDK level as a argument: Show packages that are eligable to be picked when building for specified SDK level
* all/arm/arm64/x86/x86_64: Show only packages of given architecture
* These arguments can be combined in any order and multiple architectures can be supplied
* Example command: './report_sources.sh 22 all arm arm64'
----------------------------------------------------------------------------------------"

apparchs=""
maxsdk="99"

for arg in "$@";do
	argument "$arg"
done


result="$(printf "%45s|%7s|%3s|%18s|%11s" "Application Name" "Arch." "SDK" "Version Name" "Version")
----------------------------------------------------------------------------------------"
allapks="$(find "$SOURCES/" -iname "*.apk" | awk -F '/' '{print $(NF-2)}' | sort | uniq)"
for appname in $allapks;do
	appnamefiles="$(find "$SOURCES/" -iname "*.apk" -ipath "*/$appname/*")"
	if [ "$apparchs" = "" ];then
		apparchs="$(printf "$appnamefiles" | awk -F '/' '{print $(NF-4)}' | sort | uniq)"
	fi

	for arch in $apparchs;do
		appsdkfiles="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/*")"
		appsdks="$(printf "$appsdkfiles" | awk -F '/' '{print $(NF-1)}' | sort | uniq)"

		for sdk in $appsdks;do
			if [ "$sdk" -le "$maxsdk" ];then
				appversionfile="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/$sdk/*" | tail -n 1)"
				appversion="$(basename -s ".apk" "$appversionfile")"
				appversionname="$(aapt dump badging "$appversionfile" | grep "versionName" |awk '{print $4}' |tr -d "versionName=" |tr -d "/'")"
				result="$result
$(printf "%45s| %6s| %2s| %17s| %10s" "$appname" "$arch" "$sdk" "$appversionname" "$appversion")"
				if [ "$maxsdk" != "99" ];then
					break #if a specific sdk level is supplied, we only show 1 relevant version
				fi
			fi
		done
	done
done
echo "$result"
