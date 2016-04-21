;+
; NAME: readENVIhdr
;
;
;
; PURPOSE: read an ENVI header file and return a structure of info
;
;
;
; CATEGORY: ENVI compatibility
;
; CALLING SEQUENCE: info = readENVIhdr(headerFileName)
;
; INPUTS: headerFileName - valid filename of an ENVI .hdr file.  
;
; OPTIONAL INPUTS: NONE
;
; KEYWORD PARAMETERS: NONE
;
; OUTPUTS: info, a structure similar to the ENVI map struct but
; includeing other basic info about the file, eg. ns, nl, nb,
; datatype, byte-order
;
;
; OPTIONAL OUTPUTS: NONE
;
; COMMON BLOCKS: NONE
;
; SIDE EFFECTS: NONE
;
; RESTRICTIONS: NONE
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY: Original (6/12/2002) Ethan Gutmann
;
;-
function getMapData,  line
;  print, 'Map Info Line : ', line
  tmp=strsplit(line,',',/extract)
  xoff = 0D
  yoff = 0D
  xloc = 0D
  yloc = 0D
  px = 0D
  py = 0D

  reads,  tmp(1), xoff &  reads,  tmp(2), yoff
  reads,  tmp(3), xloc &  reads,  tmp(4), yloc
  reads,  tmp(5), px   &  reads,  tmp(6), py

;;for compatibility with ENVI map struct put it in
;; these variable names
  return,  {map_Info_Struct, mc:[xoff, yoff, xloc, yloc], ps:[px, py]}
end

function bandorder, input  
  case input of 
    "bsq": return,0
    "bil": return,1
    "bip": return,2
  endcase
  return, -1
end

pro updateInfo, info, line, un
  line = strsplit(line, '=', /extract)
  case strcompress(line(0),/remove_all) of
    'samples':          info.ns = long(line(1))
    'lines':            info.nl = long(line(1))
    'bands':            info.nb = long(line(1))
    'mapinfo':          info.map = getMapData(line(1))
;    'description':      info.desc = line(1)+getDesc(un, line)
    'interleave':       info.interleave = bandorder(strcompress(line(1),/remove_all))
    'datatype':         info.type = long(line(1))
;    'byteorder':       
    else: ;print, line(0)
  endcase

end

function readENVIhdr, name

  hdrname = name+'.hdr'
  if not file_test(hdrname) then return, -1

  mapinfo = {map_Info_Struct, mc:[0d,0d,0d,0d],ps:[0d,0d]}
  desc=''
  info = {fileInfo, ns:0l, nl:0l, nb:0l, map:mapinfo,       $
                        interleave:0l, type:0l, desc:desc}


  openr, un, /get, hdrname
  while not eof(un) do begin
    line=' '
    readf, un, line
    updateinfo, info, line
  endwhile

  close, un
  free_lun, un
  return, info
end
