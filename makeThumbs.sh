#!/bin/bash

source config.txt

IFS=$(echo -en "\n\b")

# Arguments from command line

for arg in "$@"; do
  if [[ $arg =~ ^([a-z_]+)=(.*)$ ]]; then
    key=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    case $key in
      height)      Height="$value" ;;
      startdir)    StartDir="$value" ;;
      quality)     Quality="$value" ;;
      labelheight) LabelHeight="$value" ;;
    esac
  fi
done

ThumbsDir=$Height"pxHigh"

if [ $Height == '' ]
then

	echo "Missing Height Parameter"
	exit 0
fi

if [ $StartDir == '' ]
then

        echo "Missing StartDir Parameter"
        exit 0
fi

cd $StartDir

for dir in `find . -type d | grep -v thumbs`
do

	dir=$(echo $dir|sed 's/\.\///')

	if [ ! -d $StartDir/$dir/thumbs ]
	then

		mkdir $StartDir/$dir/thumbs
	fi

	cd $StartDir/"$dir"

        NumOfPics=`ls $file | egrep -i "\.(mov|flv|avi|jpg|jpeg|gif|png|bmp)$" | wc -l`

        if [ $NumOfPics -ne 0 ]
        then
		if [ ! -d $StartDir/$dir/thumbs/$ThumbsDir ]
		then

	               	mkdir $StartDir/$dir/thumbs/$ThumbsDir
		fi
		
		for pic in `ls | egrep -i "\.(jpg|jpeg|bmp|gif|png)$"`
		do

			#Detect Orientation
			Orient=`identify -format '%[exif:orientation]' $pic`
                        echo $pic $Orient
			if [[ $Orient != "1"  &&  $Orient != "" ]]
			then
				#Auto Rotate
				echo "Auto-rotating: $pic"
				/usr/bin/convert $pic -auto-orient $pic
			fi

			#Autorotate and Create a thumbnail if the file does not exist
				
			if [ ! -f $StartDir/$dir/thumbs/$ThumbsDir/$pic ]
			then
				#Create Thumbnail
				/usr/bin/convert -thumbnail x$Height -quality $Quality -strip -interlace Plane $pic $StartDir/$dir/thumbs/$ThumbsDir/$pic
				echo "Converting $pic to $StartDir/$dir/thumbs/$ThumbsDir/$pici with quality $Quality"

			fi

		done

		for mov in `ls | egrep -i "\.(flv|avi|mov|m4v|mp4)$"`
		do

                        #Create a thumbnail if the file does not exist

                        if [ ! -f $StartDir/$dir/thumbs/$ThumbsDir/$mov.jpg ]
                        then

                              	/usr/bin/ffmpegthumbnailer -i $mov -o $StartDir/$dir/thumbs/$ThumbsDir/$mov.jpg -s $Height -q 10 -a
				echo "Thumbnailing video $mov to $StartDir/$dir/thumbs/$ThumbsDir/$mov.jpg"
				/usr/bin/convert $StartDir/$dir/thumbs/$ThumbsDir/$mov.jpg -pointsize 10 -background "#d5d5d5" -gravity Center label:"VIDEO" -append $StartDir/$dir/thumbs/$ThumbsDir/$mov.jpg
                                echo "Labeling video $StartDir/$dir/thumbs/$ThumbsDir/$mov.jpg"
                       	fi


                done


	fi
done
