pro google_map, alllat, alllon, ps=ps
   IF n_elements(ps) eq 0 THEN ps=0

;x=analyze_fin2(5,-1.2,pitot=1.10,/noplot)
;alllon=smooth(x.lon,150,/nan)
;alllat=smooth(x.lat,150,/nan)

;!p.multi=[0,1,1]
      ;Google map
      IF ps eq 1 THEN cgps_open,'google_map.ps'
      centerLat = (max(alllat)+min(alllat))/2.0
      centerLon = (max(alllon)+min(alllon))/2.0
      zoom = 16
      mag=2  ;This is the 'scale' parameter in the Google API, gets a higher res version, use 'mag' to avoid use of 'scale' already
      scale = cgGoogle_MetersPerPixel(zoom)/mag
      xsize = 1200 ;600 < 640 ; Max size of Google image with this Google API
      ysize = 1200 ;600 < 640 ; Max size of Google image with this Google API
      resolution = '600x600' ;StrTrim(xsize,2) + 'x' + StrTrim(ysize,2)
      
      ; Gather the Google Map using the Google Static Map API.
      googleStr = "http://maps.googleapis.com/maps/api/staticmap?" + $
         "center=" + StrTrim(centerLat,2) + ',' + StrTrim(centerLon,2) + $
         "&zoom=" + StrTrim(zoom,2) + "&size=" + resolution + $
         "&maptype=satellite&sensor=false&format=png32" + "&scale=2"
      netObject = Obj_New('IDLnetURL')
      void = netObject -> Get(URL=googleStr, FILENAME="googleimg.png")
      Obj_Destroy, netObject
      googleImage = Read_Image('googleimg.png') 
      print,googleStr
      
      ; Set up the map projection information to be able to draw on top
      ; of the Google map.
      map = Obj_New('cgMap', 'Mercator', ELLIPSOID='WGS 84')
      uv = map -> Forward(centerLon, centerLat)
      uv_xcenter = uv[0,0]
      uv_ycenter = uv[1,0]
      xrange = [uv_xcenter - (xsize/2.0D*scale), uv_xcenter + (xsize/2.0D*scale)]
      yrange = [uv_ycenter - (ysize/2.0D*scale), uv_ycenter + (ysize/2.0D*scale)]
      map -> SetProperty, XRANGE=xrange, YRANGE=yrange
      
      ; Open a window and display the Google Image with a map grid and
      ; location of Coyote's favorite prairie dog restaurant. 
      cgDisplay, 1400, 1400, Aspect=googleImage, Title='wind'
      cgImage, googleImage[0:2,*,*], Position=[50, 50, 650, 650]/ 700.0, $
         /Keep_Aspect, OPOS=outputPosition
      map -> SetProperty, POSITION=outputPosition
      cgMap_Grid, MAP=map, /cgGRID, FORMAT='(F0.4)',/box, charsize=0.8

      cgoplot,alllon,alllat,color='blue',map=map,thick=3
      
      IF ps eq 1 THEN cgps_close,/png,width=1400

;for i=1500,5000,200 do  wind_barb,x.wspd[i],x.wdir[i],alllon[i],alllat[i],size=0.001
end
