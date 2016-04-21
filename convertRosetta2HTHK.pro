;+
; NAME: convertRosetta2HTHK
;
; PURPOSE: convert the rosetta database formate into the file format
;       expected by noahSoilsWTexture.  One texture file containing a
;       soil index, three tildas, then the soil texture name.
;       And one data file containing the output from the compHT2HK.pro program
;       column formatted [index, err,r,err,r, n,a,Ks,Ts,Tr]
;
; CATEGORY: Text File Processing / program Compatibility
;
; CALLING SEQUENCE:
;       convertRosetta2HTHK, <rosetta file>, <output texture file>,
;                            <output data file>
;
; INPUTS: rosetta file name, output texture filename, output data filename
;
; OPTIONAL INPUTS: <none>
;
; KEYWORD PARAMETERS: <none>
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE: convert sand silt clay percentages into texture names
;          find all the soils that have valid Ks data
;          format output and write it to the file
;
; EXAMPLE: convertRosetta2HTHK, "newRosetta.txt", "texture.txt", "HTHKdata.txt"
;
; MODIFICATION HISTORY:
;         edg - 8/12/2004 - original
;
;-


;; performs a mildly complex lookup to pickout texture names from
;; sand silt clay percentages
;; returns a string array
FUNCTION getTexture, data
  s=data[0,*]
  si=data[1,*]
  c=data[2,*]

  Sand=where(s-c/5.0 GT 88)
  LoamySand=where(s LT 90 AND s-c GT 70)
  SandyLoam=where(s-c LT 70 AND c lt 20 AND (s GT 52 OR (c LT 7 AND si LT 50)))
  SiltLoam=where(c LT 28 AND si GT 50 AND (si LT 20 OR c GT 12))
  Loam=where(s LT 52 AND si LT 50 AND si GT 28 AND c GT 7 AND c LT 28)
  SandyClayLoam=where(s GT 45 AND c GT 20 AND c LT 35 AND si LT 18)
  SiltyClayLoam=where(s LT 20 AND c GT 28 AND c LT 40)
  ClayLoam=where(s LT 46 AND s GT 20 AND c LT 40 AND c GT 28)
  SandyClay=where(s GT 45 AND c GT 35)
  SiltyClay=where(c GT 40 AND si GT 40)
  Clay=where(s LT 45 AND c GT 40 AND si LT 40)

  output=strarr(n_elements(s))
  
  output[Sand]="sand"
  output[LoamySand]="loamysand"
  output[SandyLoam]="sandyloam"
  output[SiltLoam]="siltloam"
  output[Loam]="loam"
  output[SandyClayLoam]="sandyclayloam"
  output[SiltyClayLoam]="siltyclayloam"
  output[ClayLoam]="clayloam"
  output[SandyClay]="sandyclay"
  output[SiltyClay]="siltyclay"
  output[Clay]="clay"

  return, transpose(output)
END



PRO convertRosetta2HTHK, rosFile, textFile, HTHKfile
  print, load_cols(rosFile, data)
  texture=getTexture(data[3:5,*])
  index=data[0,*]

  dex=where(data[7,*] NE -9.9)
  n=n_elements(dex)

;; format the texture outputfile
  output=[string(fix(index[0,dex])), replicate('~~~',1,n), $
          texture[0,dex], replicate('~~~',1,n)]

  openw, oun, /get, textFile
  printf, oun, output
  close, oun
  free_lun, oun

  output=[index[0,dex], replicate(0.9,4,n),data[11,dex],data[10,dex], $
          data[7,dex],data[9,dex],data[8,dex]]
  openw, oun, HTHKfile, /get
  printf, oun, output, format='(I6,4F6.2,2F10.4,G15.5,2F8.4)'
  close, oun
  free_lun, oun
  
END

