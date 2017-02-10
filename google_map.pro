x=analyze_fin2(5,-1.2,pitot=1.10,/noplot)
alllon=smooth(x.lon,150,/nan)
alllat=smooth(x.lat,150,/nan)

;!p.multi=[0,1,1]
      ;Google map
      centerLat = (max(alllat)+min(alllat))/2.0
      centerLon = (max(alllon)+min(alllon))/2.0
      zoom = 16
      scale = cgGoogle_MetersPerPixel(zoom)
      xsize = 600 < 640 ; Max size of Google image with this Google API
      ysize = 600 < 640 ; Max size of Google image with this Google API
      resolution = StrTrim(xsize,2) + 'x' + StrTrim(ysize,2)
      
      ; Gather the Google Map using the Google Static Map API.
      googleStr = "http://maps.googleapis.com/maps/api/staticmap?" + $
         "center=" + StrTrim(centerLat,2) + ',' + StrTrim(centerLon,2) + $
         "&zoom=" + StrTrim(zoom,2) + "&size=" + resolution + $
         "&maptype=satellite&sensor=false&format=png32"
      netObject = Obj_New('IDLnetURL')
      void = netObject -> Get(URL=googleStr, FILENAME="googleimg.png")
      Obj_Destroy, netObject
      googleImage = Read_Image('googleimg.png') 
      
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
      cgDisplay, 700, 700, Aspect=googleImage, Title='wind'
      cgImage, googleImage[0:2,*,*], Position=[50, 50, 650, 650]/ 700.0, $
         /Keep_Aspect, OPOS=outputPosition
      map -> SetProperty, POSITION=outputPosition
      cgMap_Grid, MAP=map, /BOX_AXES, /cgGRID, FORMAT='(F0.2)'

      cgoplot,alllon,alllat,color='blue',map=map,thick=2

for i=1500,5000,200 do  wind_barb,x.wspd[i],x.wdir[i],alllon[i],alllat[i],size=0.001
end
