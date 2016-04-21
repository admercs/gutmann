;; convert two input files containing head, theta, and head,
;; conductivity pairs into one output file containing theta conductivity pairs


;; get the next record from the file unit
function getNextRecord, un
  if eof(un) then return, -1

  line=""
  ;; read initial data line
  readf, un, line
  curData=float(strsplit(line, ",", /extract))
  if n_elements(curData) eq 1 then return, -1  ;no data for this record
  recordNumber=curData[0] ;; this is the record number we want to look for
  Data=curData ;; initialize data

  ;; loop until we reach the next record
  while curData[0] eq recordNumber $
    and not eof(un) $
    and n_elements(curData) gt 1 do begin

     ;; store the current data
     Data=[[Data], [curData]]

     ;;store our current pointer into the file incase this is the next record
     point_lun, -1*un, pos
     readf, un, line
     curData=float(strsplit(line, ",", /extract))
  endwhile
  Data=Data[*,1:*]
  ;; point back to where we were before we hit the wrong record
  if not eof(un) then  point_lun, un, pos

  return, Data
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read in all of the hkData to make searching through it later easier
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function readhkdata, fname
  openr, un, /get, fname
  line=""
  readf, un, line
  Data=fltarr(3)
  curData=strsplit(line, ",", /extract)
  while not eof(un) do begin
     if n_elements(curData) eq 3 then $
       Data=[[data], [float(curData)]] $
     else Data=[[Data], [[float(curData), 0, 0]]]
     
     readf, un, line
     curData=strsplit(line, ",", /extract)
  endwhile

  close, un
  free_lun, un

  return, Data[*,1:*]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; find the record that matches recNumber and return it
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getMatchRec, data, recnumber
  index=where(data[0,*] eq recnumber)
  if n_elements(index) eq 1 then return, -1 $
  else return, data[*,index]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Interpolate record one to match record 2
;;
;; In the records :
;;   column 1 is recordNumber,
;;   column 2 is the head value,
;;   column 3 is the theta or k value to be interpolated
;;
;; Rec1 should have MORE entries than Rec2
;;   Find entries in Rec1 that bracket each entry in Rec2
;;   Linearly interpolate those two entries (or average if they are the same position)
;;   Return the THIRD column from each
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION interp, rec1, rec2
  data=fltarr(3,n_elements(rec2[0,*]))

  ;; loop through all elements in rec2 matching up elements in rec1
  FOR i=0, n_elements(rec2[0,*])-1 DO BEGIN

     ;; find locations in rec1 that are <= the location in rec2
     dex=where(rec1[1,*] LE rec2[1,i])
     ;; just grab the highest of these
     topdex=dex[n_elements(dex)-1]
     ;; find locations in rec1 that are >= the location in rec2 and grab the loweset of these
     botdex=(where(rec1[1,*] GE rec2[1,i]))[0]

     ;; if we didn't encounter an error, then perform the interpolation
     IF topdex NE -1 and botdex NE -1 THEN BEGIN
        
        ;; compute the linear interpolation weights
        weight=(rec1[1,topDex]-rec2[1,i])/(rec1[1,topDex]-rec1[1,botDex])
        ;; interpolate
        interpVal=weight*rec1[2,botDex] + (1-weight)*rec1[2,topDex]

        ;; if bot and top heads are the same then really we want an average
        IF rec1[1,topdex] EQ rec1[1,botdex] THEN interpval=mean(rec1[2,botdex:topdex])
        ;; account for odd cases there botdex and topdex have the same value
        IF topdex EQ botdex THEN interpVal=rec1[2,topdex]

        ;; save the current result and continue around the loop
        data[*,i]=[rec2[0,i],interpVal, rec2[2,i]]
     ENDIF
  ENDFOR

;; return the results
  return, data
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Allign two records.
;;   First it lops off the top and bottom so that the values in the two records are
;;     in roughly the same range.
;;   Then call interpolate to shift the values in one of the records to match the other
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function allignRecords, rec1, rec2
  ;; calculate and save saturated and residual moisture content values
  thetar=min(rec1[2,*])
  thetas=max(rec1[2,*])

  ;; also find the saturated conductivity and head values
  Ks = max(rec2[2,*])
  Psi_s = min([[rec1[1,*]], [rec2[1,*]]])

  ;; find the range of head values that are (hopefully) shared between the two records.  
  ;;   find the lowest top head value
  topH=min([max(rec1[1,*]), max(rec2[1,*])])
  ;;   find the highest bottom head value
  botH=max([min(rec1[1,*]), min(rec2[1,*])])


  ;; find the starting and ending index for this range in record 1
  r1start=(where(rec1[1,*] ge botH))[0]
  r1end  =where(rec1[1,*] le topH)
  r1end=r1end[n_elements(r1end)-1]
  ;; same for record 2
  r2start=(where(rec2[1,*] ge botH))[0]
  r2end  =where(rec2[1,*] le topH)
  r2end=r2end[n_elements(r2end)-1]
  
  ;; if we are going to have less than 4 elements in the output
  ;;   than there isn't much use for it, just return and error
  IF r1end-r1start LT 4 OR r2end-r2start LT 4 THEN return, -1

  ;; if there are more records in rec1 than interpolate rec1 to match rec2
  IF r1end-r1start GT r2end-r2start THEN BEGIN
     ;; add one value to the top and bottom of rec1 to aid the interpolation of the end values
     r1start=r1start-1 >0
     r1end  =r1end+1   <(n_elements(rec1[0,*])-1)
     ;; compute the interoplation
     results=interp(rec1[*,r1start:r1end], rec2[*,r2start:r2end])
     ;; make the output (including thetar, thetas, Ks, and Psi_s as calculated above)
     results=[[[rec1[0], thetar, thetas]], $
              [[rec1[0], Ks, Psi_s]], $
              [results]]
     return, results
     
  ;; else record 2 has more entries and we should interpolate it
  ;;   (but return the results in the correct order still)
  ENDIF ELSE BEGIN 
     ;; add one value to the top and bottom of rec2 to aid the interpolation of the end values
     r2start=r2start-1 >0
     r2end  =r2end+1   <(n_elements(rec2[0,*])-1)
     ;; interpolate
     results=interp(rec2[*,r2start:r2end], rec1[*,r1start:r1end])
     ;; reorder results to match the expected output
     results=[results[0,*],results[2,*], results[1,*]]
     ;; make the output (including thetar, thetas, Ks, and Psi_s as calculated above)
     results=[[[rec1[0], thetar, thetas]], $
              [[rec1[0], Ks, Psi_s]], $
              [results]]
     return, results
  ENDELSE
END



;; duh, this probably doesn't need it's own procedure
pro writeRecord, un, record
  printf, un, record
end


;; convert two input files containing head, theta, and head,
;; conductivity pairs into one output file containing theta conductivity pairs
pro convertRos2tk, htFile, hkFile, tkOutput
  ;; open the head theta input file 
  openr, htun, /get, htFile
  ;; open the theta -conductivity output file
  openw, tkun, /get, tkOutput
  
  ;; counter to store the number of records we have calculated
  nrecs=0

  ;; read in the entire hk data file so that we can search through it quickly
  hkData=readhkData(hkFile)
  
  ;; loop through the entire ht data file
  while not eof(htun) do begin
     ;; get the next head theta record
     htrec=getNextRecord(htun)

     ;; if we got a valid record then 
     if n_elements(htrec) gt 1 then BEGIN
        ;; get the matching record from the head conductivity data
        hkrec=getMatchRec(hkData, htrec[0,0])
        
        ;; if we got a valid hk record too then
        if n_elements(hkrec) gt 1 then BEGIN
           ;; allign the two records
           tkrec=allignRecords(htrec, hkrec)

           ;; if we managed to allign them well then
           IF tkrec[0] NE -1 THEN BEGIN
              ;; write the output record
              writeRecord, tkun, tkrec
              nrecs++
           ENDIF
        endif
     endif
  endwhile

;; file cleanup
  close, htun, tkun
  free_lun, htun, tkun
end
