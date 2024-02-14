cd $HOME/PROD/bomerle/public
zip -q $HOME/BACKUP/PROD-some-jpg-jpeg.zip images/*.jpg images/*.jpeg
zip -@ -qr  $HOME/BACKUP/PROD-webp-gif-svg.zip -x "*.jpg" "*.jpeg" "images/knife/le_*/" "images/knife/l_*" < $HOME/PROCS/webp-gif-svg.list
