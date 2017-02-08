FUNCTION distance, lat1, lon1, lat2, lon2, alt1=alt1, alt2=alt2, azimuth=azimuth, greatcircle=greatcircle
   ;Returns distance in km from lat/lon1 to lat/lon2
   ;lat/lon2 can be an array.
   ;alt1/alt2, if specified, should be in km
   ;Assumes spherical Earth.
   ;AB 3/2012

   IF n_elements(greatcircle) eq 0 THEN greatcircle=0
   IF ((n_elements(alt1) ne 1) or (n_elements(alt2) eq 0)) THEN BEGIN & alt1=0 & alt2=0 & ENDIF
   
   IF (n_elements(lat1) ne 1) or (n_elements(lon1) ne 1) THEN return,0  ;Must only be one value each
   IF (n_elements(lat2) ne n_elements(lon2)) THEN return,0              ;Must be same length
   dlat=((lat1-lat2)*111.325)
   dlon=((lon1-lon2)*cos(lat1*!pi/180)*111.325)
   dalt=abs(alt1-alt2)
   dist=sqrt(dlat^2 + dlon^2 + dalt^2)
   azimuth=asin(dlon/dist)  ;Not right yet
   
   IF greatcircle eq 1 THEN BEGIN
      ;Another method from http://tchester.org/sgm/analysis/peaks/how_to_get_view_params.html
      rlon1=lon1*!pi/180
      rlat1=lat1*!pi/180
      rlon2=lon2*!pi/180
      rlat2=lat2*!pi/180
      ;Great circle distance
      d=acos(sin(rlat1)*sin(rlat2)+cos(rlat1)*cos(rlat2)*cos(rlon1-rlon2))
      dist = 180/!pi*d*111.1; 6371.0 * c  ;Radius of Earth 
      azimuth = acos( (sin(rlat2) - sin(rlat1)*cos(d) ) / (sin(d)*cos(rlat1)) )   
      w=where(sin(rlon2-rlon1) gt 0,nw)
      IF nw gt 0 THEN azimuth[w]=2*!pi - azimuth[w]
      azimuth=2*!pi-azimuth
   ENDIF

   return,dist
END
