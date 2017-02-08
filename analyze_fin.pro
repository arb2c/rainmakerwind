function analyze_fin, flight, psi_correct, fin, ahrs, wind, noplot=noplot
IF n_elements(flight) eq 0 THEN flight=3
IF n_elements(psi_correct) eq 0 THEN psi_correct=0  ;test a correction, degrees
IF n_elements(noplot) eq 0 THEN noplot=0

;Read in data
IF n_elements(fin) eq 0 THEN BEGIN
CASE flight OF
  1:BEGIN
    fin=read_fin('20161025193004_CWIP_FIN.csv', units=finunits)
    wind=read_fin('20161025193004_CWIP_WIND.csv', units=windunits)
    ahrs=read_fin('20161025193004_CWIP_AHRS.csv', units=windunits)
    gps=read_fin('20161025193004_CWIP_GPS.csv', units=gpsunits)
  END
  2:BEGIN
    fin=read_fin('20161121090704_CWIP_FIN.csv', units=finunits)
    wind=read_fin('20161121090704_CWIP_WIND.csv', units=windunits)
    ahrs=read_fin('20161121090704_CWIP_AHRS.csv', units=windunits)
    gps=read_fin('20161121090704_CWIP_GPS.csv', units=gpsunits)
  END
  3:BEGIN
    fin=read_fin('20161121094727_CWIP_FIN.csv', units=finunits)
    wind=read_fin('20161121094727_CWIP_WIND.csv', units=windunits)
    ahrs=read_fin('20161121094727_CWIP_AHRS.csv', units=windunits)
    gps=read_fin('20161121094727_CWIP_GPS.csv', units=gpsunits)
  END
ENDCASE
ENDIF

;Constants
rconst=287.04  ;J/kg/K ideal gas constant
cp=1.01*1e3    ;J/kg/K specific heat at constant pressure
cv=0.718*1e3   ;J/kg/K specific heat at constant volume
gamma=1.40     ;cp/cv specific heat ratio, this is 'kappa' sometimes

;Note: Moist air corrections also possible, generally <1% change in TAS, neglect for now.

q=fin.pitot_pres   ;This is actually pitot-static, q in Lenschow
ps=fin.static_pres
pt=q+fin.static_pres
tr=fin.amb_temp + 273.15
recov=1.0  ;Lets assume unity for now

;Compute TAS, matches RainMaker exactly
m2= 2/(gamma-1) * ((pt/ps)^((gamma-1)/gamma) - 1)           ;Mach number (squared)
tas_sq= gamma*rconst*m2*tr / (recov * (gamma-1)/2 * m2 +1)  ;Eq B.10 in TechNote 23
tas= sqrt(tas_sq)

;Compute wind, use RainMaker calculations of aircraft attitude first
time=fin.time
alpha=fin.aoa_deg * !pi/180   ;attack
beta=fin.x24v_monitor * !pi/180  ;sideslip, 8V is pressure, 24V is degrees
;Data from AHRS is at a higher rate, need to downsample with interpolation
theta=interpol(ahrs.pitch, ahrs.time, fin.time) * !pi/180   ;pitch
phi=interpol(ahrs.roll, ahrs.time, fin.time) * !pi/180  ;roll
maghead=interpol(ahrs.mag_head, ahrs.time, fin.time) * !pi/180
psi=(wind.true_head+psi_correct) * !pi/180   ;true heading
utas=tas*sin(psi)
vtas=tas*cos(psi)
lat=wind.latitude
lon=wind.longitude

;From Khelif eq. 4 and 5
d=(1 + tan(alpha)^2 + tan(beta)^2)^(-0.5)
ell=0.5  ;Distance from GPS to pitot
dt=time[1:*]-time   ;delta time
psidot=(psi[1:*]-psi)/dt
thetadot=(theta[1:*]-theta)/dt
mpd=111325.0  ;m per degree latitude at equator
up=mpd*(lon[1:*]-lon)/dt * cos(lat*!pi/180) 
vp=mpd*(lat[1:*]-lat)/dt

;Hi-res version of up and vp **Doesn't make much difference, just use up and vp above
dt_hires=gps.time[1:*]-gps.time
;lon_sm=smooth(ahrs.longitude,9)  ;These need to be smoothed before taking differential, else zeros appear
;lat_sm=smooth(ahrs.latitude,9)
up_hires=mpd*(gps.longitude[1:*]-gps.longitude)/dt_hires * cos(ahrs.latitude*!pi/180) 
vp_hires=mpd*(gps.latitude[1:*]-gps.latitude)/dt_hires 
course_hires=atan(up_hires,vp_hires) * 180/!pi
bad=where(course_hires lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN course_hires[bad] = course_hires[bad]+360
stop
up_hires=smooth(up_hires,9,/nan)
vp_hires=smooth(vp_hires,9,/nan)
up2=interpol(up_hires, gps.time[1:*], fin.time)
vp2=interpol(vp_hires, gps.time[1:*], fin.time)
course=atan(up2,vp2) * 180/!pi
bad=where(course lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN course[bad] = course[bad]+360
;psi_course=course * !pi/180   ;Use this as a test case in place of mag_head
;psi=psi_course
up=up2   ;Use hi res versions
vp=vp2
tgs=sqrt(up^2+vp^2)   ;Ground speed

;Khelif equations
uwind = up - tas*d * (sin(psi)*cos(theta) + tan(beta)*(cos(psi)*cos(phi) + sin(psi)*sin(theta)*sin(phi)) + $
           tan(alpha)*(sin(psi)*sin(theta)*cos(phi) - cos(psi)*sin(phi))) - $
           ell*(thetadot*sin(theta)*sin(psi)-psidot*cos(psi)*cos(theta))
vwind = vp -tas*d * (cos(psi)*cos(theta) + tan(beta)*(sin(psi)*cos(phi) - cos(psi)*sin(theta)*sin(phi)) + $
	   tan(alpha)*(cos(psi)*sin(theta)*cos(phi) - sin(psi)*sin(phi))) - $
	   ell*(psidot*sin(psi)*cos(theta) + thetadot*cos(psi)*sin(theta))

;Calculate using the simple approximations in TechNote eq 2.11
uwind2 = up - tas*sin(psi+beta)
vwind2 = vp - tas*cos(psi+beta)
	   
uwind_sm=smooth(uwind,5)
vwind_sm=smooth(vwind,5)
wspd=sqrt(uwind_sm^2 + vwind_sm^2)
wdir=atan(-uwind_sm, -vwind_sm) * 180/!pi
bad=where(wdir lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN wdir[bad] = wdir[bad]+360

uwind2_sm=smooth(uwind2,5)
vwind2_sm=smooth(vwind2,5)
wspd2=sqrt(uwind2_sm^2 + vwind2_sm^2)
wdir2=atan(-uwind2_sm, -vwind2_sm) * 180/!pi
bad=where(wdir2 lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN wdir2[bad] = wdir2[bad]+360

;My own simple derivation, using difference between tas and groundspeed
uwind3_sm = smooth(up-utas,5)
vwind3_sm = smooth(vp-vtas,5)
wspd3=sqrt(uwind3_sm^2 + vwind3_sm^2)
wdir3=atan(-uwind3_sm, -vwind3_sm) * 180/!pi
bad=where(wdir3 lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN wdir3[bad] = wdir3[bad]+360

IF noplot eq 0 THEN BEGIN
;Compare to RainMaker wind  ** matches pretty well
!p.multi=[0,1,4,0,0]
!p.charsize=1.5
window,0,xsize=900,ysize=800
etime=time-time[0]  ;elapsed time
etime_hires=ahrs.time-ahrs.time[0]
cgplot,etime,wind.h_wind_spd,ytitle='Wind Speed (m/s)',xtitle='Elapsed Time (s)'
cgoplot,etime,wspd,color='red'
cgoplot,etime,wspd2,color='green'
cgoplot,etime,wspd3,color='blue

cgplot,etime,wind.h_wind_dir,ytitle='Wind Direction (deg)',psym=16,symsize=0.5,xtitle='Elapsed Time (s)'
cgoplot,etime,wdir,color='red',psym=16,symsize=0.5
cgoplot,etime,wdir2,color='green',psym=16,symsize=0.5
cgoplot,etime,wdir3,color='blue',psym=16,symsize=0.5

cgplot,etime, tgs,title='TGS, TAS(red)',yr=[0,50]
cgoplot,etime,tas,color=250

cgplot, etime,course, title='Course, Mag_head(red)'
cgoplot,etime, wind.true_head+psi_correct,color=250
cgoplot,etime_hires,course_hires,color=150

;plot,wdir,title='wind dir'
;plot,psi*180/!pi,color=200,title='heading'
;write_png,'wind_comparison_flight1.png',reverse(tvrd(/true),3)
ENDIF

good=where(tas gt 10)  ;Only use in-air points for calucations
mean_wind=mean(wspd3[good],/nan)
mean_heading=mean(sin(psi[good]), /nan)
mean_course=mean(sin(course[good]*!pi/180),/nan)
corr=correlate(tgs[good],wspd3[good])
udl=total(up[good] * uwind3_sm[good], /nan)
vdl=total(vp[good] * vwind3_sm[good], /nan)
wind_std=stddev(wspd3[good],/nan)

IF noplot eq 0 THEN BEGIN
window,1,xsize=900,ysize=800
!p.multi=[0,1,2,0,0]
plot, wind.true_head[good]+psi_correct, wspd3, psym=1, xr=[0,360], yr=[0,25], xtitle='Heading',ytitle='WSPD3'
plot, wind.true_head[good]+psi_correct, wdir3, psym=1, xr=[0,360], yr=[0,360], xtitle='Heading',ytitle='WDIR3'
ENDIF

return,{mean_wind:mean_wind, mean_heading:mean_heading, mean_course:mean_course, corr:corr, udl:udl, vdl:vdl, up:up, vp:vp, $
          course:course, truehead:psi*180/!pi, maghead:maghead*180/!pi, udl_all:up[good] * uwind3_sm[good], vdl_all:vp[good] * vwind3_sm[good],$
            tas:tas, tgs:tgs, wspd:wspd, wdir:wdir, wind_std:wind_std}
END
