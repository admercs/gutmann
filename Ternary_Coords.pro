;;
;; Converts Ternary Diagram values into X-Y cartesian coordinates
;;
;; INPUT : 
;;   a must be the axis which has a value of 100% in the lower left corner
;;   b must be the vertical axis
;;   c is ignored (a+b+c=1.0)
;;
;; OUTPUT : 
;;  [X,Y]
;;     a two element array containing the x and y coordinates of the
;;     point assuming a=100% is set at (0,0) and c=100% is at (1,0)
function Ternary_Coords, a,b,c
  if a[0] gt 1 then a=a/100.
  if b[0] gt 1 then b=b/100.

  x=((sin(!dtor * 60.)*(1-a))/cos(!dtor*30.)) - $
    tan(!dtor*30.)*(sin(!dtor * 60.)*b)
  y= b*sin(!dtor * 60.)

  return, [x,y]
end
