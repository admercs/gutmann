PRO batchRunoff
  weather=file_search('IHOPUDS1*')
  namelist=file_search('noahname_*')

  FOR i=0,n_elements(weather)-1 DO BEGIN
     interpweather, weather[i], 10, 'IHOPUDS1'
     weatherdir=strmid(weather[i], 8,strlen(weather[i])-8)
     FOR j=0, n_elements(namelist)-1 DO BEGIN
        spawn, 'cp -f '+namelist[j]+' noah_offline.namelist'
        info=strsplit(namelist[j], '_', /extract)
        
        outdir=info[1]+'/'+info[2]+'/'+weatherdir+'/'
        print, outdir
        spawn, 'noah >out.log'
        IF info[1] EQ '1cm' THEN dz=1.25 ELSE dz=5
        plotRunoff, dz=dz
        spawn, 'mv out.* '+outdir
        spawn, 'mv *.ps '+outdir
     endFOR
  ENDFOR
end
