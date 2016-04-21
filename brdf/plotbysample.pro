;; reads in four 6 x 614 x 512 aviris files, writes the average value at each sample.  
;;
;; ethan gutmann 1/27/00
;;

pro plotbysample, avone, avtwo, avthree, avfour, out1, out2, out3, out4

ns = 614
nl = 512
nb = 6

openr, unone, /get, avone
openr, untwo, /get, avtwo
openr, unthree, /get, avthree
openr, unfour, /get, avfour

tmparray = intarr(nb, ns, nl)
avearr = fltarr(nb, ns)



readu, unone, tmparray

avearr = (total(tmparray, 3) / 512)

openw, outun, /get, out1
writeu, outun, transpose(avearr)

free_lun, outun



readu, untwo, tmparray

avearr = (total(tmparray, 3) / 512)

openw, outun, /get, out2
writeu, outun, transpose(avearr)

free_lun, outun



readu, unthree, tmparray

avearr = (total(tmparray, 3) / 512)

openw, outun, /get, out3
writeu, outun, transpose(avearr)

free_lun, outun



readu, unfour, tmparray

avearr = (total(tmparray, 3) / 512)

openw, outun, /get, out4
writeu, outun, transpose(avearr)

free_lun, outun

free_lun, unone, untwo, unthree, unfour

end