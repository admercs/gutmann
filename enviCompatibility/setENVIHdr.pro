;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Sets envi header info (map and ns, nl, nb, type, interleave)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro setENVIHdr, info, fname
  envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $
    interleave=info.interleave, data_type=info.type, $
    descrip=info.desc, map_info=info.map, /write
end
