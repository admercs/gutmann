pro ndviclass, ndvi, out, mask

	envi_open_file, ndvi, r_fid=fid
	envi_open_file, mask, r_fid=mfid
	envi_file_query, id=fid, ns=ns, nl=nl,nb=nb,h_map=maph

	handle_value, maph, mapinfo

	dims=[-1,mapinfo.mc(0),mapinfo.mc(2),mapinfo.mc(1),mapinfo.mc(3)]
	
	envi_check_save, /classification

	class_doit, m_fid=mfid,fid=fid,dims=dims,method=4,out_name=out,$
		pos=indgen(nb), min_classes=5,num_classes=25, iterations=5
;;typical thresh=5.0
;;	min pix in class = 0
;;	max class stdv = 1.0
;;	min class dist = 5.0
;;	max merge pair = 2
;;use max stdev = 1?

;building a mask from envi vector files
;	evf_id = envi_evf_open(evf_filename)
;	envi_evf_info, evfid, projection=proj, num_recs=nrec, data_type=dt
;	record = envi_evf_read_record(evfd_id, recordnumber)
;
;	;;probably convert evf locations to image roi locations
;
;	envi_create_roi
;	envi_define_roi
;	envi_get_roi_data
;	mask=data
;
;;/photon/dune1/soils250/spatial/utm/sand.evf
;;also in /sundog/scratch/ethan/climates/soils/sand.evf
;; is in UTM14 with 2,871 records
end
