;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Read in the generic first few lines and returns a string array
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readFirstPart, un
  line=''
  readf, un, line
  ;; if this is a line with the date in it, then read the next line
  IF strmid(line, 0,3) NE 'E01' THEN  readf, un, line
  
  ;; we need to specify that these are strings to avoid errors casting them to IDL's default float
  junk='' & d1='' & d2='' & d3='' & d4='' & d5=''

  reads, line, junk, d1, format='(A3,A3)'
  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
  reads, line, junk, d2,d3,d4,junk,d5, format='(A3,A40,A8,A8,A8,A8)'

;; skip the lines that start with 'I'
  readf, un, line
;  readf, un, line  I02 doesn't seem to exist

;; compile and return the first chunk of data
  return, [d1,d2,d3,d4,d5]
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read in the veg specific data
;;
;; return a string array
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readVegData, un
  junk='' & d1='' & d2='' & d3='' & d4='' & d5='' & d6='' & d7='' & d8=''

  line=''
  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;; N02 - FORMAT(3A1,16A1,16A1,I6,I6,F5.2,I3,4A1,F8.1,F6.2,F4.1)
  reads, line, junk, d1, format='(A3,A16)'
  result=d1

  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;N03 - FORMAT(3A1,16A1,I2,16A1,8A1,3F4.1,14A1)
  reads, line, junk, d1,d2,d3,d4,d5,d6,d7,d8, format='(A3,A16,A2,A16,A8,3A4,A14)'
  result=[result, d1,d2,d3,d4,d5,d6,d7,d8]
  
;; skip lines we aren't interested in
  FOR i=1,4 DO readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;V04 - FORMAT(3A1,16A1,F6.2,14A1,40A1)
  reads, line, junk, d1,d2,d3,d4, format='(A3,A16,A6,A14,A40)'
  result=[result, d1,d2,d3,d4]

;; skip lines we aren't interested in
  FOR i=1,4 DO readf, un, line

  return, result
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read in the soil specific data
;;
;; return a string array
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readSoilData, un
  junk='' & d1='' & d2='' & d3='' & d4='' & d5='' & d6='' & d7='' 
  d8='' & d9='' & d10='' & d11='' & d12='' & d13='' & d14=''

  line=''
  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;L02 - FORMAT(3A1,10A1,4A1,8A1,16A1,I2,I2,I2,I2,8A1,8A1,4I2,F5.2,I2)
  reads, line, junk, d1,d2,d3,d4,d5,junk,d6,junk,junk,d7,junk,junk,d8, $
         format='(A3,A10,A4,A8,A16,A2,A2,A2,A2,A8,A8,A8,A5,A2)'
  result=[d1,d2,d3,d4,d5,d6,d7,d8]

  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;L03 - FORMAT(3A1,16A1,I2,16A1,8A1,8A1,4A1,I5,14A1)
  reads, line, junk, d1,d2,d3,d4,d5,d6,junk,d7, $
         format='(A3,A16,A2,A16,A8,A8,A4,A5,A14)'
  result=[result, d1,d2,d3,d4,d5,d6,d7]
  
  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;L04 - FORMAT(3A1,13F4.1)
  reads, line, junk, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13, $
         format='(A3,13A4)'
  result=[result, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13]

  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;S01 - FORMAT(3A1,I6,I4,F5.2,F9.2,F6.2,14A1,I5,F5.2,F4.1,F4.1,I3,F5.1,F4.1)
  reads, line, junk, d1,junk, d2,junk, d3, $
         format='(A13,A5,A15,A14,A5,A5)'
  result=[result, d1,d2,d3]

  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;S02 - FORMAT(3A1,3F4.1,F5.1,2F5.2,F6.2,F5.2,2I3,F5.1,I4,F6.3,I3,2I2,F5.2, F5.1)
  reads, line, junk, d1, d2, format='(A20,2A5)'
  result=[result, d1,d2]

;; skip lines we aren't interested in
  FOR i=1,5 DO readf, un, line
  return, result
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read in the common end of a record (including the actual data)
;;
;; return a string array
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readLastPart, un
  junk='' & d1='' & d2='' & d3='' & d4='' & d5='' & d6='' & d7='' 
  d8='' & d9='' & d10='' & d11='' & d12='' & d13='' & d14=''

  line=''
  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;T01 - FORMAT(3A1,I6,I6,16A1,I3,F5.1,F5.1,I4,8A1,16A1,F4.1,I2)
  reads, line, junk, d1,d2, junk,d3, $
         format='(A3,A6,A6,A16,A3)'
  lastPart=[d1,d2,d3]
  
  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;T02 - FORMAT(3A1,I3,F5.1,I2,I3,I2,16A1,F4.1,I2,I3,I3,I6)
  reads, line, junk, d1, format='(A40,A3)'
  lastPart=[lastPart, d1]

  readf, un, line
     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;R01 - FORMAT(3A1,I4,I3,I3,F5.2,F6.2,F6.2,F5.2,F6.3,F6.3,F5.2,3F5.1,2F6.3)
  reads, line, junk, d1, junk, d2, junk, d3, $
         format='(A3,A4,A3,A3,A5,A6)'
  lastPart=[lastPart, d1,d2,d3]

;; skip lines we aren't interested in
  FOR i=1,4 DO readf, un, line

;; while there is more data to read... read it
  WHILE strmatch(line, 'D*') AND NOT eof(un) DO BEGIN

     ;; remove commas
     tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;D0x - FORMAT(3A1,I2,12F6.2)
     IF strmatch(line, 'D18*') THEN BEGIN
        ;; if the current line is 'D18' then there will only be 2 data points
        reads, line, junk, d1,d2, format='(A5,2A6)'
        lastPart=[lastPart, d1,d2]
     ENDIF ELSE BEGIN 
        ;; read all 12 data points
        reads, line, junk, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12, $
               format='(A5,12A6)'
        lastPart=[lastPart, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12]
     end

     point_lun, -1*un, pos
     readf, un, line
  ENDWHILE

     ;; remove commas
  tmp=strsplit(line, /extract, ',') & line=strjoin(tmp, '-')
;;D18 - FORMAT(3A1,I2,2F6.2)
  IF strmatch(line, 'D18*') THEN BEGIN
     ;; if the last data line was 'D18' then there will only be 2 data points to read
     reads, line, junk, d1,d2, format='(A5,2A6)'
     lastPart=[lastPart, d1,d2]
  ENDIF ELSE IF strmatch(line, 'D 6*') OR strmatch(line, 'D 5*') THEN BEGIN 
     ;; if the last data line was 'D 5' or 'D 6' then there should be the full 12 points to read.  
     reads, line, junk, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12, $
            format='(A5,12A6)'
     lastPart=[lastPart, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12]
  ENDIF ELSE IF strmatch(line, 'D 1*') THEN BEGIN
     ;; if the last data line was 'D 1' then there may only be 4 data points to read
     reads, line, junk, d1,d2,d3,d4, $
            format='(A5,4A6)'
     lastPart=[lastPart, d1,d2,d3,d4]
  ENDIF ELSE IF NOT eof(un) THEN BEGIN 
     ;; if we didn't hit the end of the file, than reset
     ;; so we are pointing at the beginning of the next record.  
     point_lun, un, pos
  ENDIF ELSE print, "ERROR: ", line

  return, lastPart
END

;; check to see if the current data record is a soil record
FUNCTION isSoil, un
  line=''
  readf, un, line

  ;; if there happens to be an I02 line, skip it
  IF strmatch(line, 'I02*') THEN readf, un, line

  return, strmid(line,0,3) EQ 'L01'
END


;; read in one file return a structure containing .soil and .veg string arrays
FUNCTION readSpecFile, filename
  openr, un, /get, filename
  line=''

  FirstPart=readFirstPart(un)
  ;; keep reading until we reach the end of the file
  WHILE NOT eof(un) DO BEGIN
     ;; Save our current position in the file so we can jump back after reading the next line
     point_lun, -1*un, pos
     ;; read a line so that we can check to see if this is a new experiment
     readf, un, line
     ;; jump back to our old position
     point_lun, un, pos
     ;; if this is a new experiment, then read in the experiment header and continue
     IF strmatch(line, 'E*') THEN FirstPart=readFirstPart(un)

     ;; check to see if the current data set is a soil or veg data set
     IF isSoil(un) THEN BEGIN
        ;; read the soil specific data
        result=[FirstPart, readSoilData(un)]
        ;; read the generic end (including the actual data)
        result=[result,readLastPart(un)]
        
        ;; if this is the first dataset we have read, then set the output to the current result
        IF n_elements(Soillist) EQ 0 THEN Soillist=result ELSE BEGIN

           ;; else add the current result to the end of the old output
           ;; if the old output and the current result are not the same size, resize the current result
           IF n_elements(SoilList[*,0]) NE n_elements(result) THEN BEGIN 
              ;; make a temporary array that is the correct length
              tmp=strarr(n_elements(Soillist[*,0]))
              ;; stick the current result into that array
              tmp[0:n_elements(result)-1]=result
              ;; set the result variable to the temporary array
              result=tmp
           ENDIF

           ;; add the current result to the old output
           Soillist=[[SoilList],[result]]
        endELSE 

     ;; if not, then it must be a veg dataset same logic as above.
     endIF ELSE BEGIN
        result=[FirstPart, readVegData(un)]
        result=[result,readLastPart(un)]
        IF n_elements(Veglist) EQ 0 THEN Veglist=result ELSE BEGIN
           ;; else add the current result to the end of the old output
           ;; if the old output and the current result are not the same size, resize the current result
           IF n_elements(VegList[*,0]) NE n_elements(result) THEN BEGIN 
              ;; make a temporary array that is the correct length
              tmp=strarr(n_elements(veglist[*,0]))
              ;; stick the current result into that array
              tmp[0:n_elements(result)-1]=result
              ;; set the result variable to the temporary array
              result=tmp
           endIF
           
           ;; add the current result to the old output
           Veglist=[[VegList],[result]]
        endELSE 
     ENDELSE 
  ENDWHILE
  
  ;; incase we didn't run into any soil or veg in this file, make a 0 entry to return.  
  IF n_elements(SoilList) EQ 0 THEN SoilList=0
  IF n_elements(VegList) EQ 0 THEN VegList=0

  ;; close the current file and free it's logical unit.  
  close, un
  free_lun, un

  ;; return the output
  return, {soil:SoilList, veg:VegList}
END


;; loop through the data printing them to the file specified by the logical unit
PRO writeSpecData, unit, data
  FOR i=0, n_elements(data[0,*])-1 DO BEGIN
     printf, unit, strjoin(data[*,i], ',')
  ENDFOR
END


PRO spec2columns, basename=basename
  IF NOT keyword_set(basename) THEN basename="dataFile"

  ;; find all files in the current directory
  files=file_search('*')
  
  ;; setup filenames based on some base name that can be specified or the default can be used
  soilFname=basename+'_soil.csv'
  vegFname=basename+'_veg.csv'

  ;; open the files for writing
  openw, soun, /get, soilFname
  openw, voun, /get, vegFname

;; these are the headers for the columns in the soil and veg files.  
  VegTopLine='ExpNumber,Location,Latitude,Longitude,Illumination,Species,SoilSeriesName,Drainage class, Textural class, Horizon, sand%, silt%, clay%, Munsell color, Soil moisture, Soil Moisture Percent, Mensell colot insitu, Surface condition, date, time, percent ground cover, irradiance azimuth angle, Observation number, view azimuth angle, fovm, DATA...'  
  SoilTopLine='ExpNumber,Location,Latitude,Longitude,Illumination,Soil order, soil suborder, soil greatgroup, subgroup name, Particle size class, mineralogy zone, parent material, soilseries name, drainageclass, textural class, horizon, AASHO classification, Unified soil classification, Munsell color, sand%, silt%, clay%, vcsand%,csand%,mcsand%,fsand%,vfsand%,csilt%,fsilt%,ASTM msand%, ASTM fsand%, ASTM fines%,Bulk density, Munsell color, Organic C, Fe oxide, Al oxide, date, time, percent ground cover, irradiance azimuth angle, Observation number, view azimuth angle, fovm, DATA...'

;; write the headers at the beginning of the files
  printf, soun, SoilTopLine
  printf, voun, VegTopLine

  ;; loop through all of the files is in the present directory
  FOR i=0,n_elements(files)-1 DO BEGIN
     print, files[i]
     ;; read in the data for the current file
     data=readSpecFile(files[i])

     ;; if there is soil data to write, then add it to the soil file
     IF n_elements(data.soil) GT 1 THEN $
       writeSpecData, soun, data.soil

     ;; if there is veg data to write, then add it to the veg file
     IF n_elements(data.veg) GT 1 THEN $
       writeSpecData, voun, data.veg

  ENDFOR

;; close the files we opened
  close, soun, voun
;; and free up the logical units that were allocated for them by the /get keyword
  free_lun, soun, voun
END
