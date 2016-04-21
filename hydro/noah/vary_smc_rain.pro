PRO writeSMC, SMCinput
  
  initFile="IHOPsoil"

  SMCi= SMCinput
  Tinit=[297.662,301.369,302.281,301.29,299.516,297.941,295.995,293.831]-273.15
  
  openw, oun, /get, initFile

  printf, oun, "Soil Profiles"
  printf, oun, "Made by vary_smc_rain.pro"
  printf, oun, "    smc1    smc2    smc3    smc4    smc5    smc6    smc7    smc8    Tsoil1  Tsoil2  Tsoil3  Tsoil4  Tsoil5  Tsoil6  Tsoil7  Tsoil8"
  printf, oun, string(replicate(SMCi, 8), format='(8F8.3)')+"  "+string(Tinit, format='(8F8.3)')
  close, oun
  free_lun, oun
END

PRO writeWeather, totalrain, totalcount
  openr, un, /get, "UDSmaster"
  openw, oun, /get, "IHOPUDS1"
  line=""
  count=0
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     IF strmatch(line, "*<RAINRATE>*") THEN BEGIN 
        parts=strsplit(line, '<RAINRATE>', /extract)
        line=parts[0]+string(totalrain/float(totalcount), format='(F8.5)')+parts[1]
        count++
     ENDIF
     printf, oun, line
  ENDWHILE
  IF count NE totalcount THEN BEGIN 
     print, "ERROR : wrong number of lines"
     print, "should be :",totalcount
     print, "was : ",count
  ENDIF
  close, oun, un
  free_lun, oun, un
END

     

PRO vary_smc_rain

  count=130 ; this is the number of time steps we will spread the rain rate over

  FOR SMC=0,50,2 DO BEGIN
     FOR rain=0,50,2 DO BEGIN
        writeSMC, SMC
        writeWeather, rain, count
        spawn, "idl <runall" ; runs noah for all SHPs/soils/textures
        outputdir="/Volumes/hydra/varying/output_"+strcompress(fix(SMC),/remove_all)+"_"+strcompress(rain, /remove_all)
        spawn, "mkdir "+outputdir
        spawn, "mv out_* "+outputdir+"/"
        print, outputdir
     ENDFOR
  ENDFOR
END

