FUNCTION vgtheta2head, otheta, thetar, thetas, a, n
  theta=otheta

  dex=where(theta LT  thetar+0.0001)
  IF dex[0] NE -1 THEN theta[dex]=thetar+0.0001
  dex=where(theta GT  thetas-0.0001)
  IF dex[0] NE -1 THEN theta[dex]=thetas-0.0001
  
  m=1.-(1/n)
  temp= ((theta-thetar)/(thetas-thetar))^(-1/m)
  temp= ((temp-1)^(1/n))/a

  return, temp
END
FUNCTION vghead2theta, ohead, thetar, thetas, a, n 
  m=1.-(1/n)
  inside=1+(a*ohead)^n
  temp=thetar+(thetas-thetar)*(inside^(-1*m))
  return, temp
END
 
