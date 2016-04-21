;aborted attempt to compare the reflectance of two entire scenes.  
; Probably ratio both scenes and output the ratioed cube as well
;  as an average, stdev, min, max reflectance ratio for the entire scene.  

pro compareRefl, basename, cmp

  if n_elements(basename) eq 0 then basename='1'
  if n_elements(cmp) eq 0 then cmp=[0,1]

  list=['.hatch', '.atrem', '.flaash', '.acorn']
  
  if cmp(0) eq 0 then begin
    data=intarr(221, 614, 512)
  endif else data=intarr(224, 614, 512)

  
  data1=intarr(224, 614, 512)
  data2=intarr(224, 614, 512)
  openr, un1, /get, basename+list(cmp(0))
  openr, un2, /get, basename+list(cmp(1))
  readu, un1, data1
  readu, un2, data2

  output=float(data1)/data2
  output=

  close, un1, un2, oun
  free_lun, un1, un2, oun
  
