pro intToFlt, infname, outfname, size

in = intarr(size/2)
out = fltarr(size/4)

openr, inun, /get, infname
readu, inun, in

openw, outun, /get, outfname
writeu, outun, FLOAT(in)

free_lun, inun, outun
end