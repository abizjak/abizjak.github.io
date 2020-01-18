avconv -i $1 -pix_fmt rgb24 -r 10 $2 ; 
convert $2 -layers Optimize $2
