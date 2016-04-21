PRO makeMovie, imagefile, column, inputFilePattern=inputFilePattern, start=start, ndays=ndays
  IF NOT keyword_set(inputFilePattern) THEN inputFilePattern="*.out"
  IF NOT keyword_set(start) THEN start=0l
  IF NOT keyword_set(ndays) THEN ndays=4l
  files=file_search(inputFilePattern)

  FOR i=long(start),48l*ndays,2 DO BEGIN
     makeImage, strcompress(i,/remove_all)+imagefile, column, $
       files=files, fileposition=i*75l
  ENDFOR
END


PRO makeImage, imagefile, column, fileposition=fileposition, $
               inputFilePattern=inputFilePattern, files=files, xs=xs,ys=ys
  IF n_elements(imagefile) EQ 0 OR $
    (NOT keyword_set(fileposition) AND NOT keyword_set(files)) THEN BEGIN
     print, 'Usage : makeImage, imageFile, [column (1)], fileposition=pos, '
     print, '       [inputFilePattern="*.out"], [files=files], [xs=xs], [ys=ys]'
     print, 'column - 1=Ts, 2=SMC, 3=LE'
     return
  END

  ;; fileposition = number of lines to skip *25, generally =128*75
  IF n_elements(column) EQ 0 THEN column=1 ; 1=ts, 2=smc, 3=evap
  line=''

  IF NOT keyword_set(files) THEN BEGIN
     IF NOT keyword_set(inputfilepattern) THEN inputfilepattern="*.out"
     files=file_search(inputFilePattern)
  ENDIF

  
  IF NOT keyword_set(xs) OR NOT keyword_set(ys) THEN BEGIN
     xs=0
     ys=0
     FOR i=ulong64(0), n_elements(files)-1 DO BEGIN
        tmp=strsplit(files[i],'_',/extract)
        xs=max([xs,fix(tmp[0])])
        ys=max([ys, fix((strsplit(tmp[1], '.',/extract))[0])])
     ENDFOR
  ENDIF

  data=fltarr(xs+1,ys+1, n_elements(column))
  
  FOR i=ulong64(0), n_elements(files)-1 DO BEGIN
     x=fix((strsplit(files[i], '_',/extract))[0])
     y=fix((strsplit((strsplit(files[i], '_',/extract))[1], '.',/extract))[0])
     openr, un, /get, files[i]
     point_lun, un, filePosition
     readf, un, line
     FOR col=0,n_elements(column)-1 DO $
       data[x,y,col]=float((strsplit(line, /extract))[column[col]])
     close, un
     free_lun, un
;     IF i MOD 1000 EQ 0 THEN print, 100* float(i)/n_elements(files)
  ENDFOR

  masterimagefile=imagefile
  masterdata=data
  FOR i=0,n_elements(column)-1 DO BEGIN 
     imagefile=strcompress(i,/remove_all)+'_'+masterimagefile
     data=masterdata[*,*,i]
     print, imagefile
     
     mx=max(data)
     mn=min(data[where(data NE 0)])
     data1=byte((data-mn) * 255.0/(mx-mn) >0)
     print, mn, mx
     write_jpeg, imagefile, data1, order=1
     
     IF column[i] EQ 1 THEN BEGIN 
        mx=330
        mn=285
     ENDIF ELSE IF column[i] EQ 2 THEN BEGIN 
        mx=1
        mn=0
     ENDIF ELSE IF column[i] EQ 3 THEN BEGIN 
        mx=1000
        mn=0
     ENDIF


     data1=byte((data-mn) * 255.0/(mx-mn) >0)
     print, mn, mx
     write_jpeg, "fixed-"+imagefile, data1, order=1
     
     openw, oun, /get, "binary-"+imagefile
     writeu, oun, data
     close, oun
     free_lun, oun
  endFOR

end
