PRO compR2shptexture, indexfile
  IF n_elements(indexfile) EQ 0 THEN indexfile="dataIndexFile"
  
  openr, un, /get, indexfile

  line=''
  nlines=0
  fnames=""
  readf, un, line
  WHILE NOT eof(un) DO BEGIN
     tmp=strsplit(line, /extract)
     nlines=[nlines,fix(tmp[0])]
     fnames=[fnames,tmp[3]]
     
     readf, un, line ; we want to ignore the last line in the file
  endWHILE
  close, un
  free_lun, un
  
  index=where(nlines GT 0)
  nlines=nlines[index]
  fnames=fnames[index]

  maxLength=6*max(nlines)/2

  data=fltarr(n_elements(fnames), maxLength)
  data[*]=-999.99
  means=fltarr(n_elements(fnames))
  SSR=fltarr(n_elements(fnames))

;; read in data from each file
  FOR j=0, n_elements(fnames)-1 DO BEGIN
     openr, un, /get, fnames[j]
     
;; skip the 24hr average data
     FOR i=0, (nlines[j]/2) DO readf, un, line
;; read the noon data
     FOR i=0, (nlines[j]/2)-2 DO BEGIN
        tmp=strsplit(line, /extract)
        data[j,i*6:((i*6)+5)]=float(tmp)
        readf, un, line
     endFOR
     tmp=strsplit(line, /extract)
     data[j,i*6:(i*6)+n_elements(tmp)-1]=float(tmp)
     dex=where(data[j,*] NE -999.99)
     means[j]=mean(data[j,dex])
     SSR[j]=total((data[j,dex]-means[j])^2)

     CLOSE, un
     free_lun, un
  ENDFOR
  
  dex=where(data[*] NE -999.99)
  ave=mean(data[dex])
  SSTO=total((data[dex]-ave)^2)

  print, SSTO, total(SSR), ave
;  print, SSR
;  print, means
;  print, fnames
  FOR i=0, n_elements(fnames)-1 DO BEGIN
     dex=where(data[i,*] NE -999.99)
     sstmp=total((data[i,dex]-ave)^2)
     print, SSR[i], sstmp, means[i], min(data[i,dex]), max(data[i,dex]), n_elements(dex),'    ',fnames[i]
  ENDFOR


  print, 1-total(SSR)/SSTO
end
