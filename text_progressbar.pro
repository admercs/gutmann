;; simple text based progess bar
;;
;; USAGE :
;;      text_progressbar, /init, [message=message]
;;
;;      for i=0, n-1 do begin
;;         <your code here>
;;         text_progressbar, n,progress=i, last=last
;;      endfor
;;
;;      text_progressbar, /done, [message=message], last=last
;;
;; NOTE : Do not put any of your own print statements in between
;;        the init and the done calls


;; print an optional message and a template that shows how far the progess
;; bar will go, then print the opening |
PRO initprogress, message
  IF n_elements(message) GT 0 THEN $
    print, message
  print, '|--------------------------------------------------|'
  print, '|', format='($,A)'
END

;; update the progess bar with one or more .
PRO updateprogress, n, progress, last=last
  current=round(50*progress/float(n))
  IF current GT last THEN BEGIN 
     FOR i=last, current-1 DO BEGIN 
        print, '.', format='($,A)' 
     ENDFOR 
     last=current
  ENDIF 
END

;; close the progess bar, finish any . that we missed,
;; print the final | and a message if supplied
PRO closeprogess, message, last=last
  
  IF last LT 50 THEN FOR i=last,50-1 DO print, '.', format='($,A)' 
  print, '|'
  IF n_elements(message) GT 0 THEN $
    print, message
END


;; this is the procedure that should always be called by the outside world
PRO text_progressbar, n, init=init, progress=progress, $
  done=done, message=message, last=last
  
  IF NOT keyword_set(last) THEN last=0
  IF keyword_set(init) THEN BEGIN 
     initprogress, message
     return
  ENDIF
  IF keyword_set(done) THEN BEGIN
     closeprogess, message, last=last
     return
  ENDIF 

  updateprogress, n, progress, last=last
END
  
