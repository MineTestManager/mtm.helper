#!/bin/bash 

jsonfile=data.json
#url="https://content.minetest.net/api/packages/?type=mod&hide=nonfree&q=humans"
url="https://content.minetest.net/api/packages/?type=mod&hide=nonfree"

curl "$url" > "$jsonfile"


echo "ignore if not empty;modname;modurl;dependencies;moddesc;Tags;Modpack;ModDB URL;Forum URL;Notes;edited;imported" > created_moddb.csv
for k in $(jq ' keys | .[]' $jsonfile); do
    value=$(jq -r ".[$k]" $jsonfile);
    name=$(jq -r '.name' <<< "$value");
    author=$(jq -r '.author' <<< "$value");
    title=$(jq -r '.title' <<< "$value");
    short_description=$(jq -r '.short_description' <<< "$value");
    short_description=${short_description//[;]/,}

    value=$(curl "https://content.minetest.net/api/packages/$author/$name/");
    repo=$(jq -r '.repo' <<< "$value");
    if [ "$repo" = "null" ]; then
        repo=""
    fi
    forums=$(jq -r '.forums' <<< "$value");

    printf ";%s;%s;" "$name" "$repo" >> created_moddb.csv

    value=$(curl "https://content.minetest.net/api/packages/$author/$name/dependencies/");
    for i in $(jq ' keys | .[]' <<< "$value"); do
        dep_value=$(jq -r ".[$i]" <<< "$value");
        is_optional=$(jq -r '.is_optional' <<< "$dep_value");
        dep_name=$(jq -r '.name' <<< "$dep_value");

        if [ "$is_optional" = "false" ]; then
            printf "%s " "$dep_name"  >> created_moddb.csv
        fi
    done

    printf ";[%s] %s;;;https://content.minetest.net/packages/%s/%s/;" "$title" "$short_description" "$author" "$name" >> created_moddb.csv
    if [ "$forums" != "null" ]; then
        printf "https://forum.minetest.net/viewtopic.php?t=%s" "$forums" >> created_moddb.csv
    fi
    printf ";;;%s\n" "$url"  >> created_moddb.csv
done
printf "# unused line must be her for read!"  >> created_moddb.csv
