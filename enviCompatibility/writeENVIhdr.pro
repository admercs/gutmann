;+
; NAME: writeENVIhdr
;
;
; PURPOSE: Write an ENVI header file so that envi does not need to be
; loaded for most of the High plains dune model
;
; CATEGORY: ENVI compatability
;
; CALLING SEQUENCE: writeENVIhdr, headerFileName, KEYWORDS
;
;
; INPUTS: headerFileName - name of the header file to be created.
;                          should end with .hdr and have the same
;                          prefix as the file it is a header for.  
;
; OPTIONAL INPUTS: NONE
;
;
; KEYWORD PARAMETERS: pro writeENVIhdr,  hdrFile,  ns=ns, nl=nl,
; nb=nb, dtype=dt, lon=lon, lat=lat, interleave=il, ps=ps,zone=zone
;
;
; OUTPUTS: file headerFileName is written.  This will overwrite any
; other file with the same name.  
;
;
; OPTIONAL OUTPUTS: NONE
;
; COMMON BLOCKS: NONE
;
; SIDE EFFECTS: NONE?
;
; RESTRICTIONS: NONE?
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY: Original 6/12/2002 Ethan Gutmann
;
;-


pro writeENVIhdr,  hdrFile,  ns=ns, nl=nl, nb=nb, dtype=dt, lon=lon, lat=lat, $
                   interleave=il, ps=ps,zone=zone, $
                   projection=projection, units=units, datum=datum
  IF NOT keyword_set(projection) THEN projection="UTM"
  IF NOT keyword_set(units) THEN units="Meters"
  IF NOT keyword_set(datum) THEN datum="WGS84"

  ERROR = 0
  if not keyword_set(ns) then begin
    print, 'ERROR : You must specify the number of samples, ns=?'
    ERROR = 1
  endif
  if not keyword_set(nl) then begin
    print, 'ERROR : You must specify the number of lines, nl=?'
    ERROR = 1
  endif
  if not keyword_set(nb) then begin
    print, 'ERROR : You SHOULD specify the number of bands, nb=?'
    print, '     Assuming there is only ONE band in this file!'
    nb = 1
  endif
  if not keyword_set(dt) then begin
    print, 'ERROR : You must specify the data type, dtype=?'
    ERROR = 1
  endif
  if not keyword_set(lon) then begin
    print, 'ERROR : You must specify the longitude of the upper left'
    print, '     corner of the image.  lon=?'
    ERROR = 1
  endif
  if not keyword_set(lat) then begin
    print, 'ERROR : You must specify the latitude of the upper left'
    print, '     corner of the image.  lat=?'
    ERROR = 1
  endif 
  if not keyword_set(il) then begin
    print, 'ERROR : You must SHOULD specify the band order, interleave=?'
    print, '                  BSQ=0, BIL=1, BIP=2'
    print, '     Assuming this file is Band Sequential (bsq)!'
    il = 0
  endif
  if not keyword_set(ps) then begin
    print, 'ERROR : You SHOULD specify the pixel size, ps=[?,?]'
    print, '     Assuming pixels are 30 meters in this file!'
    ps = [30., 30.]
  endif
  if not keyword_set(zone) then zone=14

  if ERROR then return

  openw,  oun,  /get,  hdrFile

  interleave = ['bsq','bil','bip']

  printf,   oun,   'ENVI'
  printf,   oun,   'description =  {'
  printf,   oun,   'Converted to ENVI format via writeENVIhdr.pro}'
  printf,   oun,   'samples = '+strcompress(string(ns),  /remove_all)
  printf,   oun,   'lines   = '+strcompress(string(nl), /remove_all)
  printf,   oun,   'bands   = '+strcompress(string(nb), /remove_all)
  printf,   oun,   'header offset =  0'
  printf,   oun,   'file type = ENVI Standard'
  printf,   oun,   'data type = '+strcompress(string(dt), /remove_all)
  printf,   oun,   'interleave = '+interleave(il)
  printf,   oun,   'sensor type = Unknown'
  printf,   oun,   'byte order = 1'    ;NOTE: this is for UNIX/mac, PCs it should be 0
  printf,   oun,   'x start = 1'
  printf,   oun,   'y start = 1'
  printf,   oun,   'map info =  {'+projection+',  1.000,  1.000, '+ $
            strcompress(string(lon), /remove_all)+', '+ $
            strcompress(string(lat), /remove_all)+', ' + $
            strcompress(string(ps(0)),/remove_all)+', ' + $
            strcompress(string(ps(1)),/remove_all)+', ' + $
            strcompress(string(zone),/remove_all)+',  North,  ' + $
            'units = '+units+'}'
  close,   oun &  free_lun,  oun
end

