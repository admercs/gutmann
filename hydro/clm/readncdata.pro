function readncdata, file, variables, dataonly=dataonly
  fid=ncdf_open(file)
  
;; read the date into a three element array [yyyy,mm,dd]
;;   from a file name formated as  xxx.xxx.xx.yyyy-mm-dd-fractionofDay
;  date=strsplit(file, ".", /extract)
;  date=float(strsplit(date[3], '-', /extract))
;  date[2]+=date[3]/100000.0
;  date=date[0:2]

  vid=NCDF_varid(fid, variables[0])
  IF vid EQ -1 THEN BEGIN 
     IF keyword_set(dataonly) THEN return, -1 ELSE $
       return, {data:[-1,-1], names:variables}
  ENDIF 
  NCDF_varget, fid, vid, tmp
  
  IF tmp[0] EQ -1 THEN BEGIN 
     IF keyword_set(dataonly) THEN return, -1 ELSE $
       return, {data:[-1,-1], names:variables}
  ENDIF
  tmp=transpose(reform(tmp))

  data=fltarr(1000, n_elements(tmp[0,*]))
  offset=0

  for i=0, n_elements(variables)-1 do begin
     vid=NCDF_varid(fid, variables[i])
     NCDF_varget, fid,vid,curdata
     if n_elements(curdata) gt 1 then curdata=reform(curdata)
     IF (size(curdata))[0] EQ 1 AND n_elements(curdata) GT 1 THEN curdata=transpose(curdata)

     endcol=(size(curdata))[1]+offset
     data[offset:endcol-1,*]=curdata
     offset=endcol

;     print, variables[i]
     IF n_elements(varlist) LT 1 THEN begin
        varlist=replicate(variables[i], (size(curdata))[1])
     ENDIF ELSE BEGIN
        IF (size(reform(curdata)))[0] GT 1 THEN BEGIN 
           FOR j=1,(size(curdata))[1] DO BEGIN 
              varlist=[varlist,variables[i]+strcompress(j, /remove_all)]
           endFOR
        endIF ELSE varlist=[varlist,variables[i]]
     endELSE 
  ENDFOR

  NCDF_CLOSE, fid

  data=data[0:endcol-1, *]
  
  
  IF keyword_set(dataonly) THEN $
    return, data $
  ELSE $
    return, {data:data, names:varlist} ;, date:date}
end
