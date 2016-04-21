PRO plot_non_tsvsmc, file, data=data
  read_ncdf_output, file, /nooutput, data=data

  smc=data[9,*]
  ts=(data[2,*]/(5.67051E-8))^0.25
  
  
