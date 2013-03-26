#flags
for image in `find . -name "*flag*png"`
do
	lowres=`echo $image | sed 's/-flag//g'`
	hires=`echo $image | sed 's/-flag/@2x/g'`
	convert $image -resize 16x11 $lowres
 	convert $image -resize 32x22 $hires
done

#icons
for image in `find . -name "*1024*png"`
do
	appstore=`echo $image | sed 's/-1024/-512/g'`
	lowres=`echo $image | sed 's/-1024/-icon/g'`
	hires=`echo $image | sed 's/-1024/-icon@2x/g'`
	convert $image -resize 57x57 $lowres
	convert $image -resize 114x114 $hires
	convert $image -resize 512x512 $appstore
done
