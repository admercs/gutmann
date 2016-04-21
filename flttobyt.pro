pro flttobyt, img, ns, nl, nb, out
  
  if n_elements(nl) eq 0 then begin
     envistart
     j=1
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
     
     outim = byte(inim)
     writeu, oun, outim
  endfor
  free_lun, oun, inun
  
  if j eq 1 then begin
     info.type=1
     setENVIhdr, info, out
  endif
end
