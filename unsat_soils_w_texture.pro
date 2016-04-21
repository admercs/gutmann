;+
; NAME: unsat_soils_w_texture
;
; PURPOSE: Runs unsat for all soils of a given texture specified in a pair of file.
;          Looks through the database of SHPs generated by MOSCEM (runMoscemSHP.pro)
;          and compHT2HK.pro, and uses the general.txt file from UNSODA to pick out texture
;
; CATEGORY: Batch running unsat
;
;
; CALLING SEQUENCE: unsat_soils_w_texture, texture, datafilename, texturefilename
;
; INPUTS: texture = a string identifying the texture you wish to run noah for
;                   e.g. "sandy loam" "clay" "silt clay loam" see the routine textIndex
;                   for a complete list of textures
;         datafilename = filename of compHT2HK.pro outputfile
;                   <default = vgHTHK>
;         texturefilename = filename of "general.txt" file from UNSODA database
;                   <default = newGeneral.txt>
;
;
; OPTIONAL INPUTS: <none>
;
; KEYWORD PARAMETERS: <none>
;
; OUTPUTS: noah output files named "out_texture_soilNumber"
;            where : texture = the inputtexture name (without spaces)
;                    soilNumber= the soil index number in the UNSODA database
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: file SOILPARM.TBL in current directory is overwritten
;
; RESTRICTIONS: Current Directory must have one *.inp file that is
;               otherwise setup properly for the runs of interest
;
; PROCEDURE: Get an array of [soilNumber,Texture] from the texture file.
;            Read through the datafile, for each soil
;              If it matches the texture requested, and SHPs are reasonable
;                modify *.inp file
;                Run unsat
;                Rename output file
;
; EXAMPLE: unsat_soils_w_texture, "sandyloam", "vgHTHK", "newGeneral.txt"
;
; MODIFICATION HISTORY:
;           12/20/2005 edg - Original based on noahSoilswTexture
;                            written specifically to analyze Ks distributions
;                            and infiltration distributions resulting
;                            from that given a 0 head top boundary
;-


FUNCTION getTextures, textureFile
  openr, un, /get, textureFile
  line=''
  output=strarr(2)
  i=0
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     data=strsplit(line, '~', /extract, /preserve_null)
     texture=(strsplit(data[3], '"', /extract))[0]
     output=[[output],[[data[0], texture] ]]
     i++
  ENDWHILE
  close, un
  free_lun, un
  output=output[*,1:--i]
  return, output
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; creates the input file for unsat
;; 
;; reads a master *.inp file (the first *.inp file it finds)
;; writes the new file based on the master input file, but
;;  replaces the soil properties in that file with those in data
;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO writeinputFile, data, vg=vg, cam=cam
  IF file_test('tempinput.inp') THEN file_delete, 'tempinput.inp'
  masterfile=(file_search("*.inp"))[0]

  data=float(data)
  n=data[5]
  alpha=data[6]
  DRYSMC=data[9]
  MAXSMC=data[8]
  Ks=data[7]/24. ; convert cm/day to cm/hr

  IF Ks EQ 0 THEN BEGIN
     print, "ERROR, ks = 0"
     print, "data[7]=",data[7]
  ENDIF

  comment1="Sand van Genuchten Characterization"
  dataline1= string(MAXSMC, format="(F6.3)") + ", "+$
    string(DRYSMC, format="(F6.3)") + ", "+$
    string(alpha, format="(F6.3)") + ", "+$
    string(n, format="(F6.3)") + ", "+$
    "  THET, THTR, VGA, VGN"
  comment2="Sand van Genuchten Mualem Conductivity"
  dataline2= string(2.0, format="(F6.3)") + ", "+$
    string(Ks, format="(F6.3)") + ", "+$
    string(alpha, format="(F6.3)") + ", "+$
    string(n, format="(F6.3)") + ", "+$
    "  0.5  RKMOD, SK, VGA, VGN, EPIT"

  openw, oun, /get, 'tempinput.inp'
  openr, un, /get, masterfile

  line=''
  FOR i=0,41 DO BEGIN
     readf, un, line
     printf, oun, line
  ENDFOR
  readf, un, line
  printf, oun, comment1
  readf, un, line
  printf, oun, dataline1
  readf, un, line
  printf, oun, comment2
  readf, un, line
  printf, oun, dataline2

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     printf, oun, line
  ENDWHILE


  close, oun, un
  free_lun, oun, un
END

;; run the unsat model and rename the output file
PRO rununsat, i, texture
  print, "running unsat "+texture+strcompress(i)
  spawn, "./rununsat >>outputfile"
  spawn, "mv infil out"+"_"+ $
    strcompress(texture, /remove_all)+"_"+ $
    strcompress(fix(i), /remove_all)
END


PRO unsat_soils_w_texture, texture, dataFile, textureFile, $
                           vg=vg, cam=cam, soilNum=soilNum
  IF n_elements(textureFile) EQ 0 THEN textureFile="newGeneral.txt"
  IF n_elements(dataFile) EQ 0 THEN dataFile="vgHTHK"
  print, ""
  print, "----------------------------------------"
  print, "             "+texture
  print, "----------------------------------------"
  print, ""

  IF NOT keyword_set(cam) THEN vg=1

  textData=getTextures(textureFile)
  line=''
  openr, un, /get, dataFile
  IF NOT keyword_set(soilNum) THEN BEGIN 
     openw, oun, /get, strcompress(texture, /remove_all)+".data"
     soilNum = -9999
  ENDIF

  readf, un, line ; read in the column headings and discard

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     data=float(strsplit(line, /extract))

     IF soilnum EQ -9999 OR soilNum EQ data[0] THEN BEGIN 
        IF (data[1] LT 999.9 AND data[1] NE 0 AND data[4] GT 0.25 AND $
            data[6] LT 10000000000 AND data[7] LT 10000000000 AND data[7] GT 0) THEN BEGIN
           
           dex=where(textData[0,*] EQ data[0])
           IF dex[0] NE -1 THEN BEGIN
              IF textData[1,dex] EQ texture OR $
                strcompress(textData[1,dex], /remove_all) $
                EQ strcompress(texture, /remove_all) $
                THEN BEGIN
                 IF soilNum NE -9999 THEN $
                   printf, oun, data, format='(20F15.5)'
                 writeinputFile, data, cam=cam, vg=vg
                 rununsat, data[0], texture
              ENDIF  ; (if it is the texture we are currently looking at)
           ENDIF  ; (if we can find this soil in both databases)
        ENDIF  ; (if data is valid)
     ENDIF  ; (if soilnum eq data)   
  ENDWHILE

  IF soilNum NE -9999 THEN oun=un
  close, un, oun
  free_lun, un, oun
END
