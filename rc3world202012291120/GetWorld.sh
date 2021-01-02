#!/bin/bash
#jq -r .tilesets[].image main.json
#jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"exitUrl\",.name==\"exitSceneUrl\").value" main.json
TileSetsUrlsFile="TileSetsUrls.txt"
MapsUrlsFile="MapsUrlsNew.txt"
ProtocolPrefix="https://"


function AnalyseJson {
	local jsonFull=$1
	local file=$(basename $jsonFull)
	local path=$(dirname $jsonFull)
	
	echo -n Analyse Json $jsonFull...
	local tilesets=$(jq -r .tilesets[].image $jsonFull)
	for tile in $tilesets
	do
		echo $ProtocolPrefix$path/$tile >> $TileSetsUrlsFile
	done
	local countTilesets=$(echo "$tilesets" | wc -l)
	echo -n $countTilesets Tilesets found!...
	
	local maps=$(jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"exitUrl\",.name==\"exitSceneUrl\").value" $jsonFull)
	local count=0
	for mapFull in $maps
	do
		local map=$(echo $mapFull | cut -f1 -d"#")
		if [[ "$map" == https\:\/\/* ]]
		then
			echo $map >> $MapsUrlsFile
		else
			echo $ProtocolPrefix$path/$map >> $MapsUrlsFile
		fi
	done
	local countMaps=$(echo "$maps" | wc -l)
	echo $countMaps Maps found!
	
	
}  

jsons=$(find */ -name "*.json")
for json in $jsons
do
	AnalyseJson $json
done
#AnalyseJson "lobby.maps.at.rc3.world/main.json"
