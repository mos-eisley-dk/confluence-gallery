#!/bin/bash

source config.txt

IFS=$(echo -en "\n\b")

# Arguments from command line


for arg in "$@"; do
  if [[ $arg =~ ^([a-z_]+)=(.*)$ ]]; then
    key=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    case $key in
      directory)   Dir="$value" ;;
      space)       Space="$value" ;;
      pagetitle)   PageTitle="$value" ;;
      maketoc)     MakeToc="$value" ;;
      width)       Width="$value" ;;
      grepfor)     GrepFor="$value" ;;
    esac
  fi
done

# Check Arguments

if [ $# -lt 4 ] 
then

	echo "There are not at least 4 Arguments: Dir Space PageTitle yes/no"
	exit 0
fi

if [ ! -d $MediaRoot ]
then

        echo "MediaRoot in config.txt: $MediaRoot does not exist"
        exit 0
fi

if [ $Dir == "" ]
then

	echo "Argument 1 is empty"
	exit 0
fi

if [ ! -d $MediaRoot/$Dir ]
then

	echo "Argument 1 Dir: $Dir does not exist under $MediaRoot"
	exit 0
fi

if [ ! -d $CLIHome ]
then

        echo "CLIHome  in config.txt: $CLIHome does not exist"
        exit 0
fi

if [ $MakeToc == "no" ]
then

	echo "{make-top}" > $WikiFile

else

	echo "{make-top}" > $WikiFile
	echo "{toc}" >> $WikiFile

fi

# Create Thumbnails for images and video
if [ ! -e makeThumbs.sh ]
then

        echo "makeThumbs.sh script not found here"
        exit 0
fi

if [ ! $Width == "" ]
then

	# Replace with from config.txt with command line argument width
	echo "Replacing config.txt ThumbSize $ThumbSize with argument $Width"
	ThumbSize=$Width

fi

./makeThumbs.sh height=$ThumbSize startdir=$MediaRoot/"$Dir" quality=70
./makeThumbs.sh height=$DisplaySize startdir=$MediaRoot/"$Dir" quality=100

cd $MediaRoot/"$Dir"

# Create / update Parent - so we are sure it exists
$CLIHome/confluence.sh --action storePage --space "$Space" --title "$PageTitle"  --content ""

for file in `find . -type d | grep -v "thumbs" | grep -v "cache" | egrep -i "$GrepFor" | sort`
do

#	if [ $file != "." ]
#	then

	echo "" > $WikiPageFile

        echo $file
	NumOfPics=`ls -t "$file" | egrep -i "\.(jpg|jpeg|gif|png|avi|flv|mov)$" | wc -l`

	if [ $NumOfPics -gt 0 ]
	then

		# The Directory is not emtpy, so update and create it

		file=$(echo "$file"|sed 's/\.\///g')
		group=$file

		for image in `ls "$file" | egrep -i "\.(jpg|jpeg|gif|png)$"`
		do

			# Loop all images

			file2=$(echo "$file"|sed 's/ /%20/g')

                        if [ "$file" != "." -a "$GrepFor" == "" ]
                        then

			  echo "{me-image:path=$Dir/$file2|image=$image|group=$group|thumbsize=$ThumbSize|displaysize=$DisplaySize}" >> $WikiPageFile


                        else

			  echo "{me-image:path=$Dir/$file2|image=$image|group=$group|thumbsize=$ThumbSize|displaysize=$DisplaySize}" >> $WikiFile

                        fi

		done

		for movie in `ls "$file" | egrep -i "\.(flv|avi|mov|m4v|mp4)$"` 
        	do

			# Loop all video
			file2=$(echo "$file"|sed 's/ /%20/g')

			if [ "$file" != "." -a "$GrepFor" == "" ]
                        then

               	 	  echo "{me-video:path=$Dir/$file2|image=$movie|thumbsize=$ThumbSize|displaysize=$DisplaySize}" >> $WikiPageFile

               
                        else

                          echo "{me-video:path=$Dir/$file2|image=$movie|thumbsize=$ThumbSize|displaysize=$DisplaySize}" >> $WikiFile

                        fi

                done

		title=$(echo "$file"|sed 's/\//-/g')

                if [ "$file" != "." -a "$GrepFor" == "" ]
                then

                  echo "h1. ${file}" >> $WikiFile
                  echo "{go-top}" >> $WikiFile
                  echo "{include:${title}}" >> $WikiFile
                  echo "----" >> $WikiFile

              	  $CLIHome/confluence.sh --action storePage --space "$Space" --title "${title}" --parent "$PageTitle" --file $WikiPageFile --labels "noshow"

                fi

	fi	

done

$CLIHome/confluence.sh --action storePage --space "$Space" --title "$PageTitle" --file $WikiFile

rm $WikiPageFile
rm $WikiFile
