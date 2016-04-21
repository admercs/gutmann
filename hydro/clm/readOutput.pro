function getNCdata, file, variables
  fid=ncdf_open(file)
  
;; read the date into a three element array [yyyy,mm,dd]
;;   from a file name formated as  xxx.xxx.xx.yyyy-mm-dd-fractionofDay
  date=strsplit(file, ".", /extract)
  date=float(strsplit(date[3], '-', /extract))
  date[2]+=date[3]/100000.0
  date=date[0:2]


  for i=0, n_elements(variables)-1 do begin
     vid=NCDF_varid(fid, variables[i])
     NCDF_varget, fid,vid,curdata
     if n_elements(curdata) gt 1 then curdata=reform(curdata)
     if n_elements(data) lt 1 then data=float(curdata) else $
       data=[data,float(curdata)]
     IF n_elements(varlist) LT 1 THEN $
       varlist=replicate(variables[i], n_elements(curdata)) $
       ELSE BEGIN
        IF n_elements(curdata) GT 1 THEN BEGIN 
           FOR j=1,n_elements(curdata) DO $
             varlist=[varlist,variables[i]+strcompress(j, /remove_all)]
        endIF ELSE varlist=[varlist,variables[i]]
     endELSE 
  endfor
  NCDF_CLOSE, fid
  return, {data:data, names:varlist, date:date}
end
pro readOutput, fname, outfile=outfile, all=all, plot=plot

  IF NOT keyword_set(outfile) THEN outfile="CLM_NC_OUTPUT"

  varnames=['ERRH2O','ERRSEB','ERRSOI','FCEV','FCTR','FGEV','FGR', $
            'FIRA','FIRE','FLDS','FPSN','FSA','FSDS','FSDSND','FSDSVD', $
            'FSH','FSH_G','FSH_V','FSNO','FSR','H2OSNO','H2OSOI', $
            'Q2M','QBOT','QDRAI','QDRIP','QINFL','QINTR','QMELT','QOVER','QSOIL', $
            'QVEGE','QVEGT','RAIN','SNOWDP','SOILLIQ', $
            'TBOT','TG','THBOT','TSA','TSOI','TV', 'WIND']
  
  if not keyword_set(all) then $
    varnames=varnames[[0,1,2,8,10,14,15,5,20,39,21,22,23,25,28,32,35,36,37,38,40]]
  print, transpose(varnames)
  
  fnames=file_search(fname)
  print, n_elements(fnames)

;; loop through all files reading and concatenating data
  for i=0,n_elements(fnames)-2 do begin
     curdata=getNCdata(fnames[i],varnames)

     IF n_elements(data) lt 1 THEN $
       data=[curdata.date,curdata.data] $
       ELSE $
       data=[[data],[curdata.date,curdata.data]]
  endfor

  
  if keyword_set(plot) then begin
     time=lindgen(n_elements(data[0,*]))/48.0
     for i=0,n_elements(data[*,0]) do begin
        plot, time, data[i,*], /xs, /ys, title=curdata.names[i]
        wait, 5
     endfor
  endif

;  stop
  n_cols=strcompress(n_elements(curdata.names))
  colHeaders=['Year Mon Day ',curdata.names]
  headerFormat='(A13,'+n_cols+'A20)'
  colFormat='(I4,I3,F7.3,'+n_cols+'F20.4)'
  openw, oun, /get, outfile
  printf, oun, colHeaders, format=headerFormat
  printf, oun, data, format=colFormat
  close, oun
  free_lun, oun  
end
