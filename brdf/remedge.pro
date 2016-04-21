pro remedge, imgF, outF

openr, un, /get, imgF
img=bytarr(640, 512, 3)
readu, un, img

openw, oun, /get, outF
writeu, oun, img(4:633, 4:505, *)

img=bytarr(630, 502, 3)
readu, un, img

writeu, oun, img

free_lun, un, oun

end