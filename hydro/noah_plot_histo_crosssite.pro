pro conv_files_to_one, outputfile, dirs, soils, getday=getday

    vars=[7]
    middayindex=[22,28]+getday*48.0

    for i=0, n_elements(dirs)-1 do begin
        cd, current=old, dirs[i]
        files=file_search("out_"+soils[i]+"_*")
        print, dirs[i]
        for j=0,n_elements(files)-1 do begin
            junk=load_cols(files[j], tmpdata)
            print, files[j]
            if n_elements(data) eq 0 then $
              data=[i,mean(tmpdata[vars,middayindex[0]:middayindex[1]])] $
            else $
              data=[[data],[i,mean(tmpdata[vars,middayindex[0]:middayindex[1]])]]
        endfor
        cd, old
    endfor

    openw, oun, /get, outputfile
    printf, oun, data
    close, oun
    free_lun, oun
end




pro noah_plot_histo_crosssite, getday=getday, inputfile=inputfile
    if not keyword_set(getday) then getday=48

    dirs=file_search("ihop*")

    soillist=strarr(n_elements(dirs))
    for i=0,n_elements(dirs)-1 do begin
        cd, current=old, dirs[i]
        files=file_search("out_*_*")
        soillist[i]=(strsplit(files[0],"_",/extract))[1]
        cd, old
    endfor

    if not keyword_set(inputfile) then begin
        inputfile="conv_files"
        conv_files_to_one, inputfile, dirs, soillist, getday=getday
    endif

;; load the inputfile
    junk= load_cols(inputfile, data)
;; plot the output as histograms
    histo_flux_plot, data[1,*], data[0,*], /nonames, yr=yr, /noskip, ytitle="Latent Heat Flux (W/m!U2!N)"
;; draw the names across the bottom
    for i=0,n_elements(soillist)-1 do begin
        xyouts, i, yr[0]-(yr[1]-yr[0])/20, soillist[i], align=0.5, color=0, charsize=0.4
        xyouts, i, yr[0]-2*(yr[1]-yr[0])/20, dirs[i], align=0.5, color=0, charsize=0.5
    endfor

end

