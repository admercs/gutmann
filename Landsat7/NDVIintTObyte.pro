

pro NDVIintTObyte, ndvifile, outfile
  
  envistart

  info=getFileinfo(ndvifile)

  openr, un, /get, ndvifile
  openw, oun, /get, outfile
  gain = 255./10000

  i=0
;  for i= 0, info.nb-1 do begin
     data=intarr(info.ns, info.nl)
     readu, un, data

;     index=where(data lt 0)
;     if index[0] ne -1 then data[index]=0
     data=data >0
     data=byte(data*gain)
     
     writeu, oun, data
;  endfor

  close, oun, un
  free_lun, oun, un
  
  info.type=1
  setENVIHdr, info, outfile

end
