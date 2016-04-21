pro rdasd,file=file,asdhdr=asdhdr,spectra
; RDASD reads the header information of the ASD spectra file and
; extracts the
; information specified below.  The ASD header information is returned
; to the
; calling program via the asdhdr variable.  For convenience, a
; structure is
; created to pass all of the parameters.  The raw spectra is returned
; via the
; spectra variable.
;
; written by: Gregory E. Terrie/ NASA Stennis

asdhdr = {instr_num: 0, calnum: 0, data_type: 0B, dc_corr: 0B, channels: 0, $
          ch1_wavel: 0.0, wavel_step: 0.0, itime: long(0), fov: 0, date: ' ',$
          time: ' ',data_format: 0, swir1_gain: 0, swir1_offset: 0, swir2_gain: 0,$
          swir2_offset: 0, splice1_wavelength: 0, splice2_wavelength: 0, $
          latitude:double(0), longitude:double(0)}

asd=bytarr(9088)

if (not(keyword_set(file))) then file=pickfile(/read, title='Select input file')

openr, lun, file,/get_lun

readu, lun, asd

tm_sec=fix(asd,160)                 ;sec after minute (0-59)
tm_min=fix(asd,162)                 ;min after hour   (0-59)
tm_hour=fix(asd,164)                ;hour since midnight (0-23)
tm_mday=fix(asd,166)                ;day of month (1-31)
tm_mon=fix(asd,168)                 ;months since Jan. (0-11)
tm_year=fix(asd, 170)               ;years since 1900
tm_wday=fix(asd,172)                ;days since sunday
tm_yday=fix(asd,174)                ;days since january (0-365)
tm_isdst=fix(asd,176)               ;daylight savings time flag.

asdhdr.dc_corr=byte(asd,181)        ;dc corrected flag 1=yes, 0=no

asdhdr.data_type=byte(asd,186)      ;raw=0, ref=1, rad=2, irrad=4

tmp=float(asd,191)        ;starting wavelength in nm
asdhdr.ch1_wavel=tmp

tmp=float(asd,195)       ;wavelength step in nm
asdhdr.wavel_step = tmp

asdhdr.data_format=byte(asd,199); data_format (0=float, 1=integer, 2=double, 3=unknown

tmp=fix(asd,204)
asdhdr.channels = tmp; number of channels

tmp=double(asd,350)
asdhdr.latitude = tmp; latitude

tmp=double(asd,358)
asdhdr.longitude = tmp; longitude

tmp=long(asd,390)             ;integration time in msec
asdhdr.itime = tmp

tmp=fix(asd,394)                ;foreoptics fov in degrees
asdhdr.fov = tmp

tmp=fix(asd,398)             ;calibration series
asdhdr.calnum = tmp

tmp=fix(asd,400)          ;instrument number
asdhdr.instr_num = tmp

tmp=fix(asd,436)
asdhdr.swir1_gain = tmp;swir1_gain

tmp=fix(asd,438)
asdhdr.swir2_gain = tmp;swir2_gain

tmp=fix(asd,440)
asdhdr.swir1_offset = tmp;swir1_offset

tmp=fix(asd,442)
asdhdr.swir2_offset = tmp;swir2_offset

tmp=float(asd,444)
asdhdr.splice1_wavelength = tmp ;splice1_wavelength

tmp=float(asd,448)
asdhdr.splice2_wavelength = tmp;splice2_wavelength


;spectra=float(asd,484,asdhdr.channels)

;print,'instrument no, is  ', asdhdr.instr_num
;print, 'calibration series is ', asdhdr.calnum
;print, 'Integration time is ', asdhdr.itime
;print, 'Starting wavelength is ', asdhdr.ch1_wavel
;print, 'Wavelength stepsize is ', asdhdr.wavel_step
;print, 'Number of channels is ', asdhdr.channels
asdhdr.date = strcompress(string(tm_mon+1,'/',tm_mday,'/',tm_year),/remove_all)
asdhdr.time = strcompress(string(tm_hour,':',tm_min,':',tm_sec),/remove_all)
;print, asdhdr.date, ' ', asdhdr.time

;wvl=indgen(asdhdr.channels)*asdhdr.wavel_step+asdhdr.ch1_wavel
;plot, wvl, spectra,title=file,xtitle='Wavelength (nm)'

free_lun,lun

end
