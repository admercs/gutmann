;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Reads an enviheader file.
;;          returns a struct :
;;                  ns:number of samples in the file
;;                  nl:number of lines in the file
;;                  nb:number of bands in the file
;;                  map: an envi map structure (includes utm coords
;;                  and pixelsize)
;;                  desc: The description field in the .hdr
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getFileInfo, name
  
  envi_open_file, name, r_fid=id
  
  if id eq -1 then return, {errorstruct, name:name, ns:-1, nl:-1, nb:-1}
  
  envi_file_query, id, nb=nb, nl=nl, ns=ns, h_map=maph, descrip=desc, $
    interleave=interleave, data_type=type
  handle_value, maph, map
  envi_file_mng, id=id, /remove
  
  return, {imagestruct, name:name, ns:ns, nl:nl, nb:nb, map:map, desc:desc, $
           interleave:interleave, type:type}
end
