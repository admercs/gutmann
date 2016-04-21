PRO nst_defaults, info
  bestSoil=strarr(9)
  bestSOIL[0] = 'out_sandyclayloam_860'
  bestSOIL[1] = 'out_sandyclayloam_759'
  bestSOIL[2] = 'out_sandyloam_1214'
  bestSOIL[3] = 'out_loam_1445'
  bestSOIL[4] = 'out_loam_1832'
  bestSOIL[5] = 'out_clayloam_1473'
  bestSOIL[6] = 'out_siltyclayloam_328'
  bestSOIL[7] = 'out_siltyclayloam_2122'
  bestSOIL[8] = 'out_siltyclayloam_1421'
  
  class=strarr(9)
  class[0] = 'SANDYCLAYLOAM'
  class[1] = 'SANDYCLAYLOAM'
  class[2] = 'SANDYLOAM'
  class[3] = 'LOAM'
  class[4] = 'LOAM'
  class[5] = 'CLAYLOAM'
  class[6] = 'SILTYCLAYLOAM'
  class[7] = 'SILTYCLAYLOAM'
  class[8] = 'SILTYCLAYLOAM'

  measured=strarr(9)
  measured[0] = 'IHOPUDS1.txt'
  measured[1] = 'IHOPUDS2.txt'
  measured[2] = 'IHOPUDS3.txt'
  measured[3] = 'IHOPUDS4.txt'
  measured[4] = 'IHOPUDS5.txt'
  measured[5] = 'IHOPUDS6.txt'
  measured[6] = 'IHOPUDS7.txt'
  measured[7] = 'IHOPUDS8.txt'
  measured[8] = 'IHOPUDS9.txt'

  dirs=file_search("ihop*")

  info= {nstinfo, files:bestSOIL, class:class, $
           measured:measured, dirs:dirs, days:[30,36]}
END

PRO nst_readinfo, file, info
  openr, un, /get, file
  line=''
  readf, un, line
  days=fix(strsplit(line, /extract))

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     input=strsplit(line, /extract)
     IF n_elements(files) EQ 0 THEN BEGIN
        files=input[0]
        class=input[1]
        measured=input[2]
        dirs=input[3]
     ENDIF ELSE BEGIN
        files=[files, input[0]]
        class=[class, input[1]]
        measured=[measured, input[2]]
        dirs=[dirs, input[3]]
     ENDELSE     
  ENDWHILE

  close, un
  free_lun, un
  info= {nstinfo, files:files, class:class, $
           measured:measured, dirs:dirs, days:days}
end

FUNCTION get_ts, file, days, var=var
  pos=days*48
  ndays=days[1]-days[0]+1
  junk=load_cols(file, data)
  data=data[var,*]
  IF var EQ 22 THEN data+=273.15

  data=data[pos[0]:pos[1]]

  noon=indgen(ndays)*48+24
  noondata=fltarr(n_elements(data[noon]))
  ntimes=0
  FOR offset=(-2),4 DO BEGIN 
     ntimes++
     noondata=noondata+data[noon+offset]
  endFOR
  noondata/=ntimes

  return, noondata
END


PRO noah_scatterplot_ts, inputfile
  IF n_elements(inputfile) EQ 0 THEN $
    nst_defaults, info $
  ELSE nst_readinfo, inputfile, info
  
  !p.multi=[0,1,2]
  junk=''
  var=2
  measurevar=22
  
  xr=[290,330]
  yr=xr

  FOR i=0, n_elements(info.dirs)-1 DO BEGIN
     cd, current=old, info.dirs[i]

     best=get_ts(info.files[i], info.days, var=var)
     class=get_ts(info.class[i], info.days, var=var)
     measured=get_ts(info.measured[i], info.days-11, var=measurevar)

     x=indgen(10)*100
     plot, best, measured, psym=2, title="Best Fit SHPs", /xs, /ys, xr=xr,yr=yr
     oplot, xr,yr
     r=correlate(best, measured)
     fit=linfit(best, measured)
     oplot, x, x*fit[1]+fit[0]
     xyouts, xr[0]+2, yr[1]-5, r
     xyouts, xr[0]+2, yr[1]-10, fit[0]
     xyouts, xr[0]+2, yr[1]-15, fit[1]

     plot, class, measured, psym=2, title="Class Ave SHPs", /xs, /ys, xr=xr, yr=yr
     oplot, xr,yr
     r=correlate(class, measured)
     fit=linfit(class, measured)
     oplot, x, x*fit[1]+fit[0]
     xyouts, xr[0]+2, yr[1]-5, r
     xyouts, xr[0]+2, yr[1]-10, fit[0]
     xyouts, xr[0]+2, yr[1]-15, fit[1]
     
     cd, old

  ENDFOR
END

