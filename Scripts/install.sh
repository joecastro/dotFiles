#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

sourcedirs=( vim )
sourcefiles=( vimrc profile bash_profile bashrc dircolorsrc)

targetdirs=( .vim )
targetfiles=( .vimrc .profile .bash_profile .bashrc .dircolorsrc)

sourceroot=$DIR
targetroot=~

if [ "${1,,}" == "ingest" ]
then
    echo "Ingesting current environment settings"
    temp=( "${sourcedirs[@]}" )
    sourcedirs=( "${targetdirs[@]}" )
    targetdirs=( "${temp[@]}" )
    temp=( "${sourcefiles[@]}" )
    sourcefiles=( "${targetfiles[@]}" )
    targetfiles=( "${temp[@]}" )
    temp=$sourceroot
    sourceroot=$targetroot
    targetroot=$temp
else
    echo "Installing dotFiles to environment"
fi

for i in ${!sourcedirs[*]}
do
    cp -fr $sourceroot/${sourcedirs[i]} $targetroot/${targetdirs[i]}
done

for i in ${!sourcefiles[*]}
do
    cp -f $sourceroot/${sourcefiles[i]} $targetroot/${targetfiles[i]}
done

