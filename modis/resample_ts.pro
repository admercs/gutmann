;+
; NAME: resample_ts
;
; PURPOSE: resample a series of MODIS files into UTM
;
; CATEGORY: MODIS processing
;
; CALLING SEQUENCE: resample_ts, inputdir=inputdir,
;                                outputdir=outputdir,
;                                masterPRM=masterPRM,
;                                fieldfile=fieldfile,
;                                resample=resample,
;                                workingDIR=workingDIR
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;              inputdir  : directory containing MODIS files
;                   default = /Volumes/hydra/MODIS/2002_60-273_ts_h09v05_Terra/
;              outputdir : directory to place output files
;                   default = /Volumes/hydra/MODIS/2002_60-273_ts_reproj_Terra/
;              masterPRM : sample resample parameter file
;                   default = "MASTER.prm"
;              fieldfile : text file, each line is a MODIS fieldname
;                   default = all fields in MODIS_LST (MOD11A1)
;              resample : resample program to run (full path to file
;                         if not in current directory)
;                   default = '~/heg/bin/resample'
;              workingDIR:directory to create temporary .prm file in
;                   default = './'
;
; OUTPUTS:
;          subset UTM geotiff files, one for each fieldname and MODIS file
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: YOU MUST BE ABLE TO RUN RESAMPLE e.g. you must have
;               MRDATA, MRBIN, etc. environment variables set.  
;
; PROCEDURE: find all input files, loop over input files, loop over fieldnames
;            for each fieldname-filename, write a resample .prm file
;            run resample
;
; EXAMPLE: resample_ts, inputdir='/data/modis/raw/',
;                       outputdir='/data/modis/geotiffs/',
;                       masterPRM='master.prm',
;                       fieldfile='fields.txt',
;                       workingDIR='/data/modis/'
;
; MODIFICATION HISTORY:
;        5-11-06  -  edg  - original
;        5-23-06  -  edg  - added workingDIR keyword
;                           modified to work with spaces in field names
;-


;; read a text file and return each line as a separate string in a strarray
FUNCTION readfields, file
  openr, un, /get, file
  line=''
  fields=''
  readf, un, fields
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     fields=[fields,line]
  ENDWHILE
  close, un
  free_lun, un
  return, fields
END

;; read the master.prm file and write a temp.prm file for this infile,
;; outfile, field
PRO writePRMfile, file, master, infile, outfile, field
  openr, un, master, /get
  openw, oun, file, /get
  line=''
  WHILE NOT eof(un) DO BEGIN 
     readf, un, line
     IF strmatch(line, 'INPUT_FILENAME*') THEN BEGIN 
        printf, oun, 'INPUT_FILENAME = '+infile
     ENDIF ELSE IF strmatch(line, 'FIELD_NAME*') THEN BEGIN 
        printf, oun, 'FIELD_NAME = '+field
     ENDIF ELSE IF strmatch(line, 'OUTPUT_FILENAME*') THEN BEGIN 
        printf, oun, 'OUTPUT_FILENAME = '+outfile
     ENDIF ELSE printf, oun, line ; this is the default
     
  ENDWHILE 
  close, oun, un
  free_lun, oun, un
END


;; main program
PRO resample_ts, inputdir=inputdir, outputdir=outputdir, $
                 masterPRM=masterPRM, resample=resample, $
                 workingDIR=workingdir

; setup defaults
  IF NOT keyword_set(inputdir) THEN $
    inputdir='/Volumes/hydra/MODIS/2002_60-273_ts_h09v05_Terra/'
  IF NOT keyword_set(outputdir) THEN $
    outputdir='/Volumes/hydra/MODIS/2002_60-273_ts_reproj_Terra/'
  IF NOT keyword_set(masterPRM) THEN $
    masterPRM='MASTER.prm'
  IF NOT keyword_set(fieldfile) THEN $
    fields=['LST_Day_1km', 'QC_Day','Day_view_time','Day_view_angl', $
           'LST_Night_1km','QC_Night','Night_view_time','Night_view_angl', $
           'Emis_31','Emis_32','Clear_day_cov','Clear_night_cov'] $
  ELSE fields=readfields(fieldfile)
  IF NOT keyword_set(resample) THEN resample='~/heg/bin/resample'
  IF NOT keyword_set(workingDIR) THEN workingDIR='.'

;; move to a directory we can create param.prm file in
  cd, workingDIR, current=oldDIR

;; find input hdf files to process
  files=file_search(inputdir+path_sep()+'*.hdf')

;; setup a progressbar indicator
  text_progressbar, /init
;; loop over all files
  FOR i=0, n_elements(files)-1 DO BEGIN
;; loop over all fields of interest
     FOR field=0,n_elements(fields)-1 DO BEGIN 
        curfile=file_basename(files[i], '.hdf')

;; deal with spaces in field names for the output files
        outfile=outputdir+path_sep()+curfile+'_'+ $
                strjoin(strsplit(fields[field],/extract,' '), '_')+'.tif'

;; write the resample prm file
        writePRMfile, 'param.prm', masterPRM, files[i], outfile, $
                      fields[field]
;; run resample
        spawn, resample+' -p param.prm >resample.log'
     ENDFOR
;; update progress bar
     text_progressbar, n_elements(files), progress=i, last=last
  ENDFOR
;; close progress bar
  text_progressbar, /done, last=last

;; return to our original directory
  cd, oldDIR
END

