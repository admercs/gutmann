FUNCTION match_psi_theta_data, data, ttime, ptime
  nd=n_elements(ttime)
  np=n_elements(ptime)

  IF ttime[0] LT ptime[0] THEN BEGIN 
     i=0
     WHILE ttime[i] LT ptime[0] DO i++
     ttime=ttime[i:*]
  ENDIF
  
;; throw out the first data point from ptime as it is simultaneous
;; with the first ttime data point while all the rest of the data
;; will be averages across theta (ttime)
  last=0
  outputdata=data[*,0]
  FOR i=1, n_elements(ptime)-1 DO BEGIN 
     curdata=fltarr(n_elements(data[*,0]))
     count=fltarr(n_elements(data[*,0]))
     WHILE ttime[last] LT ptime[i] AND last LT n_elements(ttime)-1 DO BEGIN
        FOR j=0, n_elements(data[*,0])-1 DO $
          IF data[j,last] NE -6999 THEN BEGIN 
           curdata[j]+=data[j,last]
           count[j]++
        ENDIF

        last++
     ENDWHILE
     curdata/=count
     outputdata=[[outputdata],[curdata]]
     
  ENDFOR
  
  return, outputdata
END



PRO phils_data, thetafile, psifile, _extra=e
  IF n_elements(thetafile) EQ 0 THEN thetafile="thetadata.txt"
  IF n_elements(psifile) EQ 0 THEN psifile="psidata.txt"

  junk=load_cols(thetafile, tdata)
  junk=load_cols(psifile, pdata)
  psicol=[2,3,4,6,7,8,10,11,12]
  thetacol=[2,3,4,10,11,12,6,7,8]
  
  theta_superset=tdata[thetacol, *]
  psi=pdata[psicol,*]
  
  ptime=pdata[0,*]
  thour=fix(tdata[1,*]/100)
  tmin=fix(tdata[1,*]) MOD 100
  ttime=tdata[0,*]+thour/24.0 + tmin/(60.0*24.0)
  
  theta=match_psi_theta_data(theta_superset, ttime, ptime)

  titlea=['Open', 'Canopy', 'Edge']
  titleb=['60cm', '30cm', '15cm']
  !p.multi=[0,3,3]
  IF !d.name EQ 'X' THEN BEGIN 
     !p.charsize=2
     window, xs=1000,ys=1000
  ENDIF

  FOR i=0,n_elements(psicol)-1 DO BEGIN
     valid=where(psi[i,*] NE -6999)
     IF valid[0] NE -1 THEN $
       plot, psi[i,valid], theta[i,valid], $
             /psym, /ys, _extra=e, $  ; xr=[10,-200], $
             title=titlea[i/3]+'  '+titleb[i MOD 3], $
             xtitle="Water Potential (cm?)", $
             ytitle="Water Content (cm!E3!N/cm!E3!N)"
  ENDFOR

END

