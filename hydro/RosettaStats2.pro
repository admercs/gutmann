PRO RosettaStats2, infile, outfile
  print, load_cols(infile, data)
  s=data[3,*]
  si=data[4,*]
  c=data[5,*]
  n=data[11,*]
  db=data[1,*]

;; translation from Lenhard
  b=1.0/(n-1.0) * 1.0/(1-0.5^(n/(n-1)))

  openw, oun, /get, outfile
  openw, run, /get, outfile+".rawls"
  openw, aun, /get, outfile+".ahuja"
  openw, uun, /get, outfile+".unsoda"
  un=[run, aun, uun]

  values=[0.05, 0.25, 0.5, 0.75, 0.95]

  FOR i=0,10 DO BEGIN
     CASE i OF 
; sand
        0:  dex=where(s-c/5.0 GE 88)
; loamy sand
        1:  dex=where(s LE 90 AND s-c GE 70)
; sandy loam
        2:  dex=where(s-c LE 70 AND c lt 20 AND (s GE 52 OR (c LE 7 AND si LE 50)))
; silt loam
        3:  dex=where(c LE 28 AND si GE 50 AND (si LE 20 OR c GE 12))
; loam
        4:  dex=where(s LE 52 AND si LE 50 AND si GE 28 AND c GE 7 AND c LE 28)
; sandy clay loam
        5:  dex=where(s GE 45 AND c GE 20 AND c LE 35 AND si LE 18)
; silty clay loam
        6:  dex=where(s LE 20 AND c GE 28 AND c LE 40)
; clay loam
        7:  dex=where(s LE 46 AND s GE 20 AND c LE 40 AND c GE 28)
; sandy clay
        8:  dex=where(s GE 45 AND c GE 35)
; silty clay
        9:  dex=where(c GE 40 AND si GE 40)
; clay
        10: dex=where(s LE 45 AND c GE 40 AND si LE 40)
     endCASE
     
     data=b[dex]
     curdb=db[dex]
     IF n_elements(data) GT 4 THEN $
       printf, oun, [percentiles(value=values,data), n_elements(data)] $
       ELSE printf, oun, [0,0,0,0,0,n_elements(data)]
     
     ;; loop through the three databases
     FOR j=1,3 DO BEGIN
        thisdex=where(curdb EQ j)
        IF n_elements(thisdex) GT 4 THEN $
          printf, un[j-1], [percentiles(value=values,data[thisdex]), n_elements(thisdex)] $
          ELSE printf, un[j-1], [0,0,0,0,0,n_elements(thisdex)]
     ENDFOR
  ENDFOR
  
  FOR i=0,2 DO begin
     close, un[i]
     free_lun, un[i]
  endFOR
     close, oun
     free_lun, oun

end
