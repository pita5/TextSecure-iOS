for image in `find . -name "*_1024.png"`
do
	retina=`echo $image | sed 's/_1024/@2x/g'`
	lowres=`echo $image | sed 's/_1024//g'`
	convert $image -resize 57x57 $lowres
	convert $image -resize 114x114 $retina
done
