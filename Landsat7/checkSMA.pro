;; make NDVI of all original images
;; plot NDVI vs all sma bands for the full image and for subset
;;        make subset from [667,85] to [1066,624]
;; print r^2, slope,offset for both
;; print, min,max (& 1,2%) for both NDVI and each sma band (full and subset)

;; original images in raw as resized2, resized3, resized4,... resized24
;; sma images in SMA as *.sma
pro checkSMA
  envistart

  originals=file_search('raw/resized*.hdr')
  smaFiles = file_search('SMA/*.sma')
  nfiles=strarr(n_elements(originals))
  
;; for all original files make an NDVI image in ndvi/
;; NOTE these have not been calibrated to reflectance to are
;;   somewhat meaningless... somewhat.  
  for i=0, n_elements(originals)-1 do begin
     thisfile=strsplit(originals[i], '.', /extract)
     basefile=strsplit(thisfile[0], '/', /extract)
     basefile=basefile[1]
     thisfile=thisfile[0]
     originals[i]=thisfile
     print, thisfile
     ndvifile ='ndvi/'+basefile+'.ndvi'
     print, ndvifile

     info=getFileInfo(thisfile)
     openr, un, /get, thisfile
     data=make_array(info.ns, info.nl, 2, type=info.type)
    
;; Point to band 3 and read two bands
     point_lun, un, info.ns*info.nl*info.type*2
     readu, un, data

     NDVI=(float(data[*,*,1])-data[*,*,0]) $
        / (float(data[*,*,1])+data[*,*,0])
     print, min(data[*,*,0]), max(data[*,*,0])
     print, min(ndvi[*,*,0]), max(ndvi[*,*,0])
     
     openw, oun, /get, ndvifile
     writeu, oun, NDVI
     close, oun, un
     free_lun, oun, un
     
     nfiles[i]=ndvifile
     ninfo=info
     ninfo.nb=1
     ninfo.type=4
     setENVIhdr, ninfo, ndvifile
  endfor

  old=!D.name
  set_plot, 'ps'
  device, file='SMAplot.ps',xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches, $
    set_font='Times', /tt_font, font_size=14
  for i=0, n_elements(smaFiles)-1 do begin
     sinfo=getFileinfo(smaFiles[i])

     filenum=strsplit(smaFiles[i], '/', /extract)
     filenum=strsplit(filenum[1], '.', /extract)
     filenum=strsplit(filenum[0], '-', /extract)
     filenum=fix(filenum[0])
     print, filenum
     ndvifile='ndvi/resized'+strcompress(filenum, /remove_all)+'.ndvi'
     print, ndvifile
     ninfo=getFileInfo(ndvifile)
     openr, nun, /get, ndvifile
     ndvi=make_array(ninfo.ns, ninfo.nl, type=ninfo.type)
     readu, nun, ndvi
     close, nun
     free_lun, nun

     openr, sun, /get, smaFiles[i]
     data=make_array(sinfo.ns, sinfo.nl, type=sinfo.type)
     for j=0, sinfo.nb-2 do begin
        readu, sun, data

        print, ''
        print, ''
        print, smaFiles[i], ' sma band ', strcompress(j)
        result=regress(transpose(reform(ndvi, n_elements(ndvi))), $
                       reform(data,n_elements(data)), const=const, $
                       sigma=sigma, ftest=ftst, correlation=rval)
        print, 'Rsq ', rval^2
        print, ''
        print, 'Fit = ', const, result
        print, ''
        print, 'Max NDVI,      Min NDVI,      Max SMA,      Min SMA'
        print, max(ndvi), min(ndvi), max(data), min(data)
        plot, ndvi, data, psym=3, title=smaFiles[i]+strcompress(j)

        subndvi=ndvi[667:1066,85:623]
        subdata=data[667:1066,85:623]
        print, ''
        print, 'SUBSET ',smaFiles[i], ' sma band ', strcompress(j)
        result=regress(transpose(reform(subndvi, n_elements(subndvi))), $
                       reform(subdata,n_elements(subdata)), const=const, $
                       sigma=sigma, ftest=ftst, correlation=rval)
        print, 'Rsq ', rval^2
        print, ''
        print, 'Fit = ', const, result
        print, ''
        print, 'Max SUBNDVI,      Min SUBNDVI,      Max SubSMA,      Min SubSMA'
        print, max(subndvi), min(subndvi), max(subdata), min(subdata)
        plot, subndvi, subdata, psym=3, title='SUBSET'+smaFiles[i]+strcompress(j)

     endfor
     close, sun
     free_lun, sun
  endfor
  device, /close
;  !p.multi=save
  set_plot, old
  
end
