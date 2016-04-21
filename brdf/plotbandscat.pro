pro plotbandscat, avFile, lsFile, samples, lines, outFname

openr,un1,/get,avFile
avimg=intarr(samples,lines,6)
readu,un1,avimg
free_lun,un1

openr,un1,/get,lsFile
lsimg=intarr(samples,6, lines)
readu,un1,lsimg
free_lun,un1


titles=['!17Band 1', $
           'Band 2', $
           'Band 3', $
           'Band 4', $
           'Band 5', $
           'Band 7']

save=!p.multi
!p.multi=[0,2,3]

;set_plot,'ps'
;device,file=outFname,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches

for i=0,5 do plot,fix(avimg(*,*,i)),lsimg(*,i,*),psym=3, $
    xrange=[0,5000],/xstyle, $
    yrange=[0,500],/ystyle, $
    charsize=2.0, $
    title=titles(i)

;device,/close
set_plot,'x'

!p.multi=save

end

