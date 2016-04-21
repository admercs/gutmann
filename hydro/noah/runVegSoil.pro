PRO writeVegtype, veg
  openw, oun, /get, 'IHOPluse'
  printf, oun, 'Site'
  printf, oun, '1       2       3       4       5       6       7       8       9'
  printf, oun, strcompress(veg)
  close, oun
  free_lun, oun
END
PRO writeSoiltype, soil
  openw, oun, /get, 'IHOPstyp'
  printf, oun, 'Site'
  printf, oun, '1       2       3       4       5       6       7       8       9'
  printf, oun, strcompress(soil)
  close, oun
  free_lun, oun
END

PRO writeSoilPARM, B
  openr, un, /get, 'SOILMASTER.TBL'
  openw, oun, /get, 'SOILPARM.TBL'
  line=''
  FOR i=0, 23 DO BEGIN
     readf, un, line
     printf, oun, line
  ENDFOR
  line=string('22, '+strcompress(B)+',    0.060,    -0.472,   0.339,   0.236,   0.069,  1.07E-4,  0.608E-6,   0.060,  0.92, "SAND"')
  printf, oun, line

  close, un, oun
  free_lun, oun, un
END

PRO binaryplotSoil
  window, 5, xs=500, ys=500
  !p.multi=[0,1,1]

  xr=[615,622]
  yr=[300,315]
  day=lindgen(34992)/48.
  j=load_cols('sandoutput',sand)

  openr, un, /get,'BetaData'
  size=0l
  FOR B=0.5,15,0.1 DO BEGIN 
     readu, un, size
     data=fltarr(size)

     readu, un, data
     plot, day,data, /xs, /ys, xr=xr, yr=yr, title=B
;     oplot, day,sand[3,*]*1000+275
     readu, un, data
;     plot, day,data, /xs, /ys, xr=xr, yr=[-0.1,0.4], title=B
     wait, 0.2
;     oplot, day,sand[3,*]*50-0.1
     
  ENDFOR
  close, un
  free_lun, un
END



PRO plotVarSoil
  day=lindgen(34992)/48.
  window, 5, xs=1000,ys=1000
  xr=[615,625]
  yr=[270,330]
  !p.multi=[0,1,2]
  openw, oun, /get, 'BetaData'
  FOR B=0.5,15,0.1 DO BEGIN 
     j=load_cols('B-'+strcompress(B, /remove_all)+'.out', BetaData)
     plot,day,betadata[8,*], xr=xr, yr=yr,/xs,/ys, $
          title='Temperature  B='+strcompress(B)
     plot,day,betadata[18,*], xr=xr,yr=[0,0.4], /xs,/ys, $
          title='Water Content  B='+strcompress(B)
     writeu, oun, long(n_elements(BetaData[8,*])), $
             BetaData[8,*], BetaData[18,*]
     
  ENDFOR 
  close, oun
  free_lun, oun
END


PRO runVarSoil
  FOR B=0.5,15,0.1 DO BEGIN 

;; setup soil type file (SOILPARM.TBL)
     writeSoilPARM, B
     
;; run NOAH model
     spawn, '../../bin/NOAH >& output'
     print, B
;; move output file into a better named file
     spawn, string('mv fort.111 B-'+strcompress(B, /remove_all)+ $
                   '.out')
  ENDFOR 

END

PRO runVegSoil
  FOR soil=20,23 DO BEGIN 
     FOR veg=28, 34 DO BEGIN

;; setup veg and soil type files (IHOPstyp and IHOPluse)
        writeVegtype, veg
        writeSoiltype, soil

;; run NOAH model
        spawn, '../../bin/NOAH >& output'
        print, soil, veg
;; move output file into a better named file
        spawn, string('mv fort.111 s'+strcompress(soil, /remove_all)+ $
                      'v'+strcompress(veg, /remove_all)+'.out')
     ENDFOR 
  ENDFOR 

END

PRO plotVegSoil

  set_plot, 'ps'
  oldp=!p.multi
  !p.multi=[0,1,3]
  device, file='VegSoil.ps', xsize=8.3, ysize=10.8, /inches, $
          set_font='Times',/tt_font, xoff=0.1, yoff=0.1, font_size=16
  soilName=['mysand  ', 'MY clay', 'sand  ', 'clay']
  vegName=['Bare Soil', 'GRASS=100', 'GRASS=80', 'GRASS=60', 'GRASS=40', $
       'GRASS=20', 'GRASS=0']
  day=lindgen(34991)/48.
  xr=[615, 625]
  yr=[270,320]
  FOR sdex=0, 2, 2 DO BEGIN
     FOR veg=28, 34 DO BEGIN
        soil=20+sdex
        fname='s'+strcompress(soil, /remove_all)+ $
              'v'+strcompress(veg, /remove_all)+'.out'
        j=load_cols(fname, sand)
        soil=21+sdex
        fname='s'+strcompress(soil, /remove_all)+ $
              'v'+strcompress(veg, /remove_all)+'.out'
        j=load_cols(fname, clay)
        
        title=soilName[soil-20]+'/sand  '+vegName[veg-28]
        
        plot, day,sand[8,*], xr=xr, yr=yr, /ys, /xs, $
              title=string(title,' Temperature')
        oplot, day, clay[8,*], line=2
        oplot, day, clay[3,*]*1000 +yr[0]+0.5

        plot, day, sand[8,*]-clay[8,*], xr=xr, yr=[-15,10], /xs, $
              title=string(title, ' Delta T')
        oplot, day, clay[3,*]*500 -14.5

        plot, day,sand[18,*], xr=xr, yr=[0,0.5], /ys, /xs, $
              title=string(title,' Soil Moisture')
        oplot, day, clay[18,*], line=2
        oplot, day, clay[3,*]*10

        print, sdex, veg

     ENDFOR 
  ENDFOR 

  device, /close
  set_plot, 'x'
  !p.multi=oldp
END 
