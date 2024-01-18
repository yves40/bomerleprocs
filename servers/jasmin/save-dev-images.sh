cd $HOME/DEV/bomerle/public
zip -q $HOME/BACKUP/some-jpg-jpeg.zip images/*.jpg images/*.jpeg
zip -@ -qr  $HOME/BACKUP/webp-gif-svg.zip -x "*.jpg" "*.jpeg" "images/knife/le_*/" "images/knife/l_*" < $HOME/PROCS/webp-gif-svg.list
