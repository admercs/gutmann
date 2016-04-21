FUNCTION resizeImg, data, in_ns, in_nl, out_ns, out_nl
;;
;;Check this for syntax as I typed it up pretty quick.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;Note that this algorithm requires that the input data size (number of
;;  samples and number of lines) be an integer multiple of the output
;;  data size.  You can change rebin to congrid if you don't want this
;;  to be the case, but I think you will lose accuracy
;;
;; Assume data is an array that you want to resample
;;   data is initially in_ns x in_nl
;;          (input number of samples x input number of lines)
;;   and you want to resample it to out_ns x out_nl
;;          (output number of samples x output number of lines)
;;   you also want a standard deviation array
;;
;; Assume we do not want to look at any pixels that have a
;;   data value of 9999
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ratioS=in_ns/out_ns
  ratioL=in_nl/out_nl

;; create our output arrays
  newData=fltarr(out_ns,out_nl)
  stdData=fltarr(out_ns,out_nl)

;; this is a little complicated, print the output of this on
;;  the commandline to understand what it does.
;	map=rebin(indgen(out_ns,out_nl), in_ns,in_ns, /sample)

;; loop through all of the pixels in the new image averaging
;;   and computing standard deviations appropriately
  for i=0, n_elements(newData)-1 do begin

;; find all pixels in the input image corresponding to the
;;   current output pixel, and data values are Not Equal to 9999
;		index=where(map eq i and data ne 9999)


;; NEW
;; duh, as long as we know the ratio of old pixels to new pixels (and
;;   it is an integer), we can just calculate which pixels to use, this
;;   saves calling where on a potentially HUGE array over and over again
;;   this can probably also be used to read a file line by line if
;;   you don't have the RAM to read it all in at once.

;; integer division and modulo arithmetic.
     curS= i MOD out_ns
     curL= i / out_ns

;; not entirely sure about the -1 part...
     curData=data[ratioS*curS:(ratioS*curS)+ratioS-1, $
                  ratioL*curL:(ratioL*curL)+ratioL-1]

;; calling where on a small array is cheap computationally
     index = where(curData NE 9999)
;; if there were no valid data points than store 9999 in the output
     if index[0] eq -1 then begin
        newData[i]=9999
        stdData[i]=9999
     endif else begin
;; otherwise compute the mean and standard deviation
        newData[i]=mean(curData[index])
        stdData[i]=stdev(curData[index])
     endelse
  ENDFOR
  return, [[newData],[stdData]]
END
