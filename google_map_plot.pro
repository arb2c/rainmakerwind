; docformat = 'rst'
;+
; This is an example program to demonstrate how to create a Google Map plot
; with Coyote Graphics routines. Note that if you get "curl" errors when you
; try to access the Google web page, it may be you have to use a proxy for 
; the network. If so, you may have to modify the "netObject" variable in
; the code below with the name of your proxy server and its port number, like this::
; 
;    netObject = Obj_New('IDLnetURL', PROXY_HOSTNAME="nameOfYourProxy", PROXY_PORT=yourPortNumber
;    
; Other proxy keywords may also be required. See the on-line documentation of IDLnetURL for details.
;
; :Categories:
;    Graphics
;    
; :Examples:
;    Save the program as "google_map_plot.pro" and run it like this::
;       IDL> .RUN google_map_plot
;       
; :Author:
;    FANNING SOFTWARE CONSULTING::
;       David W. Fanning 
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: david@idlcoyote.com
;       Coyote's Guide to IDL Programming: http://www.idlcoyote.com
;
; :History:
;     Change History::
;        Written, 23 January 2013 by David W. Fanning.
;
; :Copyright:
;     Copyright (c) 2013, Fanning Software Consulting, Inc.
;-
PRO Google_Map_Plot
 
   ; Set up variables for the plot. Normally, these values would be
   ; passed into the program as positional and keyword parameters.
   centerLat = 40.6D
   centerLon = -105.1D
   zoom = 12
   scale = cgGoogle_MetersPerPixel(zoom)
   xsize = 600 < 640 ; Max size of Google image with this Google API
   ysize = 600 < 640 ; Max size of Google image with this Google API
   resolution = StrTrim(xsize,2) + 'x' + StrTrim(ysize,2)
   
   ; Gather the Google Map using the Google Static Map API.
   googleStr = "http://maps.googleapis.com/maps/api/staticmap?" + $
      "center=" + StrTrim(centerLat,2) + ',' + StrTrim(centerLon,2) + $
      "&zoom=" + StrTrim(zoom,2) + "&size=" + resolution + $
      "&maptype=terrain&sensor=false&format=png32"
   print,googleStr
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
   cgDisplay, 700, 700, Aspect=googleImage, Title='Google Image with Coyote Graphics'
   cgImage, googleImage[0:2,*,*], Position=[50, 50, 650, 650]/ 700.0, $
     /Keep_Aspect, OPOS=outputPostion
   map -> SetProperty, POSITION=outputPosition
   cgMap_Grid, MAP=map, /BOX_AXES, /cgGRID, FORMAT='(F0.2)'
   cgPlotS, -105.1, 40.6, PSYM='filledstar', SYMSIZE=3.0, MAP=map, COLOR='red'
   
   ; Add a label for the restaurant.
   xy = map -> Forward(-105.1, 40.6)
   loc = Convert_Coord(xy[0], xy[1], /Data, /To_Normal)
   cgText, loc[0], loc[1]+0.025, 'Prairie Dog Restaurant', /Normal, $
      Alignment=0.5, Color='red', Font=0
   
END ;*****************************************************************

; This main program shows how to call the program and produce
; various types of output.

  ; Display the plot in a graphics window.
  Google_Map_Plot
    
  ; Create a PostScript file.
  cgPS_Open, 'google_map_plot.ps'
  Google_Map_Plot
  cgPS_Close
  
  ; Create a PNG file with a width of 600 pixels.
  cgPS2Raster, 'google_map_plot.ps', /PNG, /Portrait, Width=600

END
