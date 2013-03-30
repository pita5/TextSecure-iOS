for image in `find . -name "*@2x*png"`
do
	lowres=`echo $image | sed 's/@2x//g'`
	convert $image -resize 50% $lowres
done
