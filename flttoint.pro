pro flttoint, img, ns, nl, nb, out
  
  if n_elements(nl) eq 0 then begin
     out=ns
     info=getFileInfo(img)
     ns=info.ns
     nl=info.nl
     nb=info.nb
  endif
  
  openr, inun,/get,img
  openw,oun,/get, out
  
  inim=fltarr(ns, nl)
  for i=0, nb-1 do begin
     readu, inun, inim
     
     outim = FIX(inim*10000)
     writeu, oun, outim
  endfor
  free_lun, oun, inun
  
  info.type=2
  setENVIhdr, info, out
  
end
