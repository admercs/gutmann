;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Compares to files to see if they have identical numbers of
;; samples and lines, and also makes sure that the map information
;; for the two files is identical
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function filesEqual, rinfo, iinfo
  mapEq = (rinfo.map.mc[0] eq iinfo.map.mc[0]) and $
          (rinfo.map.mc[1] eq iinfo.map.mc[1]) and $
          (rinfo.map.mc[2] eq iinfo.map.mc[2]) and $
          (rinfo.map.mc[3] eq iinfo.map.mc[3]) ; and $
; while the rest of these are technically necessary, combunequal won't
; fix them anyway so we won't bother checking them.  
;          (rinfo.map.ps[0] eq iinfo.map.ps[0]) and $
;          (rinfo.map.ps[1] eq iinfo.map.ps[1]) and $
;          (rinfo.map.proj.name eq iinfo.map.proj.name) and $
;          (rinfo.map.proj.type eq iinfo.map.proj.type) and $
;          (rinfo.map.proj.params[0] eq iinfo.map.proj.params[0])


  return, (rinfo.nl eq iinfo.nl) $
          and (rinfo.ns eq iinfo.ns) $
          and (rinfo.nb eq iinfo.nb) $  ;combunequal can fix 6 vs 7 bands
          and mapEq
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Checks the file information on two files.  If they have the same
;;  number of samples and lines and map information it leaves them
;;  alone.  If they differ, it calls combunequal to combine the files
;;  spatially, the result is two new files, combined1 and combined2
;;  that are the ref and input filenames respectively.  It also
;;  changes the names of these files in the calling routine.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro setSizes, ref, input
;; read envi header info
  rinfo=getFileInfo(ref)
  iinfo=getFileInfo(input)

;; combine the two files so they line up if they are not already set
;; up that way.
  if not filesEqual(rinfo, iinfo) then begin
     ;write the combunequal input file
     openw, oun, /get, 'combmeta'
     printf, oun, 2
     printf, oun, ref
     printf, oun, input
     close, oun   & free_lun, oun
     ;combine the two files, new names will be combined1 and combined2
     combunequal, 'combmeta', 'combined', /split

;; change our internal filenames and file info to the new files
     ref   = "combined1"
     input = "combined2"
  endif
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Computes the Spectral Angle between each pixel in two files
;; 
;; Merely a wrapper around sam_image_byte.pro that takes filenames and
;; returns a data array.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function calc_SAM, img1, img2
  info=getFileInfo(img1)
  info2=getFileInfo(img2)

  samFile = img1+'_SAM_'+img2

;; this is where the actual work happens
;  if not file_test(samfile) then $
  IF (info.type EQ 1) AND (info2.type EQ 1) THEN BEGIN 
     sam_image_byte, img1, img2, samFile, info.ns, info.nl, info.nb
  ENDIF ELSE $
    sam_image, img1, img2, samFile, ns=info.ns, nl=info.nl, nb=info.nb, $
                    data_size_1=info.type, data_size_2=info2.type

;; now setup a nice ENVI hdr file for the SAM file
  info.nb=1
  info.type=4
  info.desc="Spectral Angle Map between 2 files : "+img1+" and "+img2
  setENVIhdr, info, samFile

;; read in the resulting data file and return the data
  samData=fltarr(info.ns, info.nl)
  openr, un, /get, samFile
  readu, un, samData
  close, un    & free_lun, un

  return, samData
end  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Finds the indices into img that contain the top N pixels values
;;
;;  e.g. if you want to find the 10,000 pixels in img that have the
;;  largest values simply pass and img and 10,000 for topN.
;;
;;  Returns a MINIMUM of topN indices.  Because multiple pixels may
;;  have the same value it will probably return more than topN
;;  pixels.
;;
;;  OPTIONAL keyword : nbins
;;     if nbins is specified it determines how finely the histogram
;;     for the image is.  ie it determines the number of bins in the
;;     histogram used to find the topN values, by default a value of
;;     10000 is used.
;;
;;  RETURNS :   Indices of the topN points in img or
;;              -1 on ERROR
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function botNindices, img, topN, nbins=nbins

  if not keyword_set(nbins) then nbins=10000

;; compute the histogram
  hist=histogram(fix(img*10000), nbins=nbins, reverse_indices=R)

  npix=0
  i=1     ;; skip DN 0 because it will be all BLACK pixels in the original

;; search down the histogram until we have topN points (or more)
  while npix lt topN and i lt nbins do begin
     npix=npix+hist[i]
     i=i+1
  endwhile

;; simple ERROR checking,
;;     If npix lt topN then we have found enough pixels
;;     If R[i+1] eq R[nbins] then we haven't found any pixels
  if (npix lt topN) or (R[0] eq R[i+1]) then begin
     print, 'ERROR : histogram error finding top 10,000 vals, found', npix, ' pixels'
     return, -1
  endif

  plot, hist[1:n_elements(hist)-1]
  print, i
  print, R[0]
  print, R[i+1]

;; find the indices into the original sam image that have these values
  index = R[R[1]:R[i+1]-1]    ;; stupid reverse index notation
                                  ;; see IDL reference guide for help
  print, n_elements(index)
  if n_elements(index) gt topN*2 then begin
     index = where(fix(img*10000) lt i and img ne 0)
     print, 'ERROR : initially too many points, used where now I have : '
     print, '        ', strcompress(n_elements(index)), ' points'
  endif

  return, index
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  MAIN PROGRAM
;;
;;     ref  = img to normalize to
;;     input= img to normalize
;;     ouput= normalized img
;;     
;;  OPTIONAL (defaults should be fine)
;;     topN = N pixels to use
;;     nbins= N histogram bins to use
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro SAM_normalize, ref, input, output, topN=topN, nbins=nbins
  envistart
  if not keyword_set(topN) then  topN = 10000
  if not keyword_set(nbins) then nbins= 10000
  
;; resize the files if they do not match number of lines, samples, and
;; map info
  setSizes, ref, input
  
;; read envi header info
  rinfo=getFileInfo(ref)
  iinfo=getFileInfo(input)
  
;; Calculate SAM values for ref vs input  (mask for clouds?)
  sam = calc_SAM(ref, input)
  
;; find top 10,000 SAM values  
  index = botNindices(sam, topN, nbins=nbins)
  print, 'Found : ', strcompress(n_elements(index)), ' matching pixels'
;; for each band, linfit and normalize
  openr, run, /get, ref
  refIMG=make_array(rinfo.ns, rinfo.nl, type=rinfo.type)
  openr, iun, /get, input
  inpIMG=make_array(iinfo.ns, iinfo.nl, type=iinfo.type)
  openw, oun, /get, output
  
  normal=fltarr(2,rinfo.nb)
  maxOut = intarr(rinfo.nb)
  maxInp = intarr(rinfo.nb)
;; plotting stuff
  set_plot, 'ps'
  device,file= output+".ps" ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches, $
         set_font='Times', /tt_font, font_size=14

;; loop through all bands correcting them
  for i=0, rinfo.nb-1 do begin
     readu, run, refIMG
     readu, iun, inpIMG
;     fit=linfit(refIMG[index], inpIMG[index])
;;this is the slope for a line that passes through the origin
     newfit=mean(inpIMG[index])/mean(refIMG[index])
     fit=[0,newfit]
     print, fit

     
     dex=where(inpIMG eq 0, count)
     if count eq 0 then return
     
     IF rinfo.type EQ 1 THEN BEGIN
        outIMG = byte((inpIMG-fit[0])/fit[1])
     ENDIF ELSE IF rinfo.type EQ 2 THEN BEGIN
        outIMG = FIX((inpIMG-fit[0])/fit[1])
     ENDIF ELSE IF rinfo.type EQ 4 THEN outIMG = (inpIMG-fit[0])/fit[1]
     
     outIMG[dex] = 0
     maxOut[i] = max(outIMG)
     maxInp[i]  = max(inpIMG)

     print, 'Slope = ',strcompress(fit[1]), $
            '  Offset = ',strcompress(fit[0])
     print, 'Band ',strcompress(i+1),$
            '   Max =',maxOut[i], $
            '   was :', maxInp[i]
     plot, refIMG[index], inpIMG[index], psym=3
     normal[*,i]=fit
     writeu, oun, outIMG     
  endfor
  device, /close
  set_plot, 'X'
  close, oun, iun, run
  free_lun, oun, iun, run
  
;; write output header
  iinfo.type=rinfo.type
  setENVIhdr, iinfo, output
  
;; write text file with normalization values
  openw, oun, /get, output+'.txt'
  printf, oun, normal
  printf, oun, maxOut
  close, oun    & free_lun, oun
  
;; write jpeg of input B3 scaled by 1/resizeFactor with top 10,000 points
;; marked
  resizeFactor=1

  outIMG=byte(outIMG * (255./maxOut[i-1]))
  jpeg = rebin(outIMG, rinfo.ns, (rinfo.nl), 3)
  temp = jpeg[*,*,0]
  temp[index] = 255
  jpeg[*,*,0] = temp
  jpeg=congrid(jpeg, rinfo.ns/resizeFactor, rinfo.nl/resizeFactor,3)
  
  write_jpeg, output+'.jpg', jpeg, order=1, true=3
;; write jpeg of input B3 w/o top 10,000 points
;; write jpeg of ref   B3
  
end
