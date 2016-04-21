pro read_ncdf_Output, fname, outfile=outfile, nooutput=nooutput, $
  all=all, plot=plot, data=data, simple=simple

  IF NOT keyword_set(outfile) THEN outfile="CLM_NC_OUTPUT"
  IF n_elements(fname) EQ 0 THEN fname=(file_search('clm3*h0*.nc'))[0]

  varnames=['ERRH2O','ERRSEB','ERRSOI','FCEV','FCTR','FGEV','FGR', $
            'FIRA','FIRE','FLDS','FPSN','FSA','FSDS','FSDSND','FSDSVD', $
            'FSH','FSH_G','FSH_V','FSNO','FSR','H2OSNO','H2OSOI', $
            'Q2M','QBOT','QDRAI','QDRIP','QINFL','QINTR','QMELT','QOVER','QSOIL', $
            'QVEGE','QVEGT','RAIN','SNOWDP','SOILLIQ', $
            'TBOT','TG','THBOT','TSA','TSOI','TV', 'WIND','time']
  
  if not keyword_set(all) AND NOT keyword_set(simple) then $
    varnames=varnames[[43,1,8,10,14,15,5,20,39,21,22,23,25,28,32,35,36,37,38,40,33]]
  IF keyword_set(simple) THEN $
    varnames=varnames[[43,8,37,3,4,5,15,6,12,21]]
    ;  time  LWup, Ts?, LH_canE, LH_transp, LH_E, SH, SWdown, SMC(1-10?), 
;  print, transpose(varnames)
  
;; read the data
  NCdata=readncdata(fname,varnames)

  if keyword_set(plot) then begin
     time=lindgen(n_elements(NCdata.data[0,*]))/48.0
     for i=0,n_elements(NCdata.data[*,0])-1 do begin
        plot, time, NCdata.data[i,*], /xs, /ys, title=NCdata.names[i]
        wait, 5
     endfor
  endif

;  stop
  IF NOT keyword_set(nooutput) THEN BEGIN 
     n_cols=strcompress(n_elements(NCdata.names))
                                ; colHeaders=['Year Mon Day ',NCdata.names]
;  headerFormat='(A13,'+n_cols+'A20)'
;  colFormat='(I4,I3,F7.3,'+n_cols+'F20.4)'
     headerFormat='('+n_cols+'A20)'
     colFormat='('+n_cols+'F20.4)'
     openw, oun, /get, outfile
     printf, oun, NCdata.names, format=headerFormat
     printf, oun, NCdata.data, format=colFormat
     close, oun
     free_lun, oun  
  ENDIF

;; return the data if the data keyword was supplied
  data=NCdata.data
end
