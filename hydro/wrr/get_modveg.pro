FUNCTION get_modveg, nosand=nosand, norunoff=norunoff, nodrain=nodrain, value=value
  IF keyword_set(nodrain) THEN IF nodrain EQ 1 THEN nodrain=0.3
  IF keyword_set(norunoff) THEN IF norunoff EQ 1 THEN norunoff=0.3
  IF NOT keyword_set(value) THEN value=[0.25,0.75]

  dirs=file_search('ihop*_*', /test_directory)
  aves=fltarr(11,12,2)
  vars=fltarr(11,12,2)
  perc=fltarr(11,12,2)
  perctop=fltarr(11,12,2)
  percbot=fltarr(11,12,2)
  fullave=fltarr(11,2)
  fullvars=fltarr(11,2)
  fullptop=fltarr(11,2)
  fullpbot=fltarr(11,2)
  allsoils=fltarr(11,2000,2)
  nsoils=0
  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, dirs[i], current=old
     
     site=fix(strmid(dirs[i],4,1))
     IF site EQ 3 THEN site=0 ELSE IF site EQ 8 THEN site=1

     veglev=fix((strsplit(dirs[i], '_', /extract))[1])/10
     
     combfile='comb1';(file_search('comb*'))[1]
     junk=load_cols(combfile, data)
     FOR class=0, 11 DO BEGIN 
        index=where(data[1,*] EQ class)
        IF index[0] NE -1 THEN BEGIN 
           aves[veglev,class, site] = mean(data[12,index])
           vars[veglev,class, site] = stdev(data[12,index])
           tmp=percentiles(data[12,index], value=[0.25,0.75])
           perc[veglev,class, site] = tmp[1]-tmp[0]
           percbot[veglev,class, site] = tmp[0]
           perctop[veglev,class, site] = tmp[1]
        ENDIF
     ENDFOR
     tmpdata=data
     IF keyword_set(nosand) THEN data=data[*,where(data[1,*] NE 0)]
     IF keyword_set(nodrain) THEN data=data[*,where(data[17,*] LT nodrain)]
     IF keyword_set(norunoff) THEN data=data[*,where(data[16,*] LT norunoff)]
     

     fullave[veglev,site]=mean(data[12,*])
     fullvars[veglev,site]=stdev(data[12,*])
     tmp=percentiles(data[12,*], value=value)
     fullpbot[veglev,site]=tmp[0]
     fullptop[veglev,site]=tmp[1]

     nsoils=n_elements(index)
     allsoils[veglev,0:n_elements(index)-1,site]=tmpdata[12,index]

     cd, old
  ENDFOR

  allsoils=allsoils[*,0:nsoils-1,*]
  return, {aves:aves, vars:vars, perc:perc,  percbot:percbot,  perctop:perctop, $
           fullave:fullave, fullvars:fullvars, fullptop:fullptop, fullpbot:fullpbot, $
           allsoils:allsoils, percs:value}
END
