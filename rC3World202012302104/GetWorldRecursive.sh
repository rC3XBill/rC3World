#!/bin/bash
#Crawler to download #rC3
IFS=$'\n'
UrlsOrgSource="lobby.maps.at.rc3.world/main.json"
UrlsFileTiles="UrlsTiles.txt"
UrlsFileSounds="UrlsSounds.txt"
UrlsFileMaps="UrlsMaps.txt"
UrlsFileNotFound="UrlsFileNotFound.txt"
JsonFilesFinished="JsonFilesFinished.txt"
Tokens="Tokens.txt"
ProtocolPrefix="https://"
Retries=1
Delay=3

function GetFileFromWeb {
	local url=$1
	local destination=${url#"$ProtocolPrefix"}
	if [[ ! -f $destination ]]; then
		for (( i=0; i<$Retries; ++i)); do
			echo Download known file from $url to $destination!
			
			wget --timeout=$Delay --tries=$Retries --no-check-certificate -nv --retry-connrefused -nc -x $url #-w 3 -N
			
			if [[ ! -f $destination ]] && [ $Retries -gt 1 ]; then
				echo Download unsuccesful retry in $Delay...
				sleep $Delay
			else
				break
			fi
		done
				
		if [[ ! -f $destination ]]; then
			echo "Download unsuccesful (added to" $UrlsFileNotFound "):" $url
			echo $url >> $UrlsFileNotFound
		fi
	fi
}

function AnalyseJson {
	local jsonFull=$1
	local file=$(basename $jsonFull)
	local path=$(dirname $jsonFull)
	
	echo Analyse Json $jsonFull for Tilesets...
	local tilesets=$(jq -r .tilesets[].image $jsonFull)
	for tile in $tilesets
	do
		echo $ProtocolPrefix$path/$tile >> $UrlsFileTiles
		GetFileFromWeb $ProtocolPrefix$path/$tile
	done
	local countTilesets=$(echo -n "$tilesets" | wc -l)
	echo $countTilesets Tilesets in $jsonFull found!
		
	local sounds=$(jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"playAudio\",.name==\"playAudioLoop\").value" $jsonFull)
	for sound in $sounds
	do
		echo $ProtocolPrefix$path/$tile >> $UrlsFileSounds
		GetFileFromWeb $ProtocolPrefix$path/$tile
	done
	local countSounds=$(echo -n "$sounds" | wc -l)
	echo -n $countSounds Sounds found!...

	echo Analyse Json $jsonFull for Tokens...
	local tokens=$(jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"getBadge\").value" $jsonFull)
	for token in $tokens
	do
		echo $token >> $Tokens
	done
	local countTokens=$(echo -n "$sounds" | wc -l)
	echo $countTokens Tokens in $jsonFull found!
	
	echo Marked $jsonFull as done to prevent unnessary recrusion!
	echo $jsonFull >> $JsonFilesFinished
	
	echo Analyse Json $jsonFull for other Maps...
	local maps=$(jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"exitUrl\",.name==\"exitSceneUrl\").value" $jsonFull)
	for mapFull in $maps
	do
		local map=$(echo $mapFull | cut -f1 -d"#")
		
		if [[ "$map" == https\:\/\/* ]]
		then
			echo $map >> $UrlsFileMaps
			GetFileFromWeb $map
			local destination=${map#"$ProtocolPrefix"}
			local nextJsonFile=$(realpath -m $destination --relative-base=./)
			if [[ -f $nextJsonFile ]]; then
				if ! grep -q $nextJsonFile $JsonFilesFinished; then
					AnalyseJson $nextJsonFile #form correct panth without ".."
				fi
			else
				echo Json $nextJsonFile not Found - ignored for Analyses
				echo $nextJsonFile >> $JsonFilesFinished
			fi
		else
			echo $ProtocolPrefix$path/$map > $UrlsFileMaps
			GetFileFromWeb $ProtocolPrefix$path/$map
			local nextJsonFile=$(realpath -m $path/$map --relative-base=./)
			if [[ -f $nextJsonFile ]]; then
				if ! grep -q $nextJsonFile $JsonFilesFinished; then
					AnalyseJson $nextJsonFile #form correct panth without ".."
				fi
			else
				echo Json $nextJsonFile not Found - ignored for Analyses
				echo $nextJsonFile >> $JsonFilesFinished
			fi
		fi
	done
	local countMaps=$(echo -n "$maps" | wc -l)
	echo $countMaps Maps in $jsonFull found!
	
	echo $jsonFull Really done!
}

echo -n >> $JsonFilesFinished
GetFileFromWeb $ProtocolPrefix$UrlsOrgSource
AnalyseJson $UrlsOrgSource

