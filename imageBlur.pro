PRO imageBlur, inputfile, outfile
  IF n_elements(outfile) EQ 0 THEN outfile ="output"
  read_jpeg, inputfile, data
  sz=size(data)
  if sz[2] gt 1024 then begin
  	data=data[*,0:1000,*]
  	endif

  sz[2]=1001
  osz=sz
  n_pixels=sz[2]*sz[3]
  start=1000
  i=0
  WHILE sz[0] GT 1 DO BEGIN
     data=congrid(data, 3,sz[2]/2, sz[3]/2, /interp)
     sz=size(data)
     if sz[0] LE 1 then begin
     	newdata=bytarr(3,osz[2], osz[3])
     	newdata[0,*,*]=data[2]
     	newdata[1,*,*]=data[1]
     	newdata[2,*]=data[0]
     	print, data
     	write_jpeg,outfile+strcompress(start-i, /remove_all)+".jpg", $
     		newdata, true=1
     endif else $
	     write_jpeg, outfile+strcompress(start-i, /remove_all)+".jpg", $
    	             congrid(data, osz[1],osz[2],osz[3]), true=1
     i=i+1
  endWHILE

END
