;Command line scripts for various flights

;=====================================================================
;Flight 4 01/20/2017
;Find pitot adjustment minimum, best=1.15
for i=8,18 do begin &  x=analyze_fin2(4,0,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wdir[2000:4000]) & endfor

;Find heading adjustment minimum, best=-2
for i=-8,4 do begin &  x=analyze_fin2(4,i,/noplot,pitot=1.15) & print,i,stddev(x.wdir[2000:4000]) & endfor

;=====================================================================
;Flight 5 02/07/2017
;Find pitot adjustment minimum, best=1.10, stddev much lower in general than flight #4 (33ish vs 4.6ish)
for i=8,18 do begin &  x=analyze_fin2(5,0,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wdir[1500:5000]) & endfor

;Find heading adjustment minimum, best=-1
for i=-8,4 do begin &  x=analyze_fin2(5,i,/noplot,pitot=1.10) & print,i,stddev(x.wdir[1500:5000]) & endfor


;=====================================================================
;Flight 7 04/13/2017
;I think this already has the 1.1 correction applied...  low winds so using wspd intead of wdir
;Find pitot adjustment minimum, best= 1.12,
for i=5,15 do begin &  x=analyze_fin2(7,0,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd[2000:8000]) & endfor

;Find heading adjustment minimum, best=-1
for i=-8,4 do begin &  x=analyze_fin2(7,i,/noplot,pitot=1.12) & print,i,stddev(x.wspd[2000:8000]) & endfor


;=====================================================================
;Flight 9 06/05/2017

for i=5,15 do begin &  x=analyze_fin2(9,0,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd[3000:8000]) & endfor

;Find heading adjustment minimum, best=-0.5
for i=-8,8 do begin &  x=analyze_fin2(9,-1+i/10.0,/noplot,pitot=1.1) & print,i,stddev(x.wspd[3000:8000]) & endfor

;=====================================================================
;Flight 11 07/06/2017 full CWIP in China
;points 3500-6500 nearly make a closed loop

;Best = 1.09 with no heading offset.  1.06 when using -2.8 degree offset
for i=5,15 do begin &  x=analyze_fin2(11,-2.8,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd[3500:6600]) & endfor

;Getting best adjustment at large value of -2.8 degrees
for i=-20,-15 do begin &  x=analyze_fin2(11,-1+i/10.0,/noplot,pitot=1.09) & print,-1+i/10.0,stddev(x.wspd[3500:6600]) & endfor

;=====================================================================
;Flight 12 07/08/2017 full CWIP in China  - better flight than above
;points 800-1400 altitude 3000m
;points 1600-2800 altitude 3700m
;points 400-3800 whole flight, best 1.03, -3.5 deg


a=400 & b=3800
;Best = 1.09 with no heading offset.  1.03 when using -2.8 degree offset
for i=0,15 do begin &  x=analyze_fin2(12,-3.5,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd[a:b]) & endfor

;Getting best adjustment at large value of -3.5 degrees
for i=-35,-15 do begin &  x=analyze_fin2(12,-1+i/10.0,/noplot,pitot=1.05) & print,-1+i/10.0,stddev(x.wspd[a:b]) & endfor

;=====================================================================
;Flight 13 09/12/2017 Albatross test flight with Don Lenschow, looking at SS and AoA here
a=2000 & b=7000      ;SS and AoA maneuvers started around 7200, ignore those
;Find pitot adjustment minimum, best= 1.15,
for i=13,19 do begin &  x=analyze_fin2(13,0,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd[a:b]) & endfor

;Find heading adjustment minimum, best=0
for i=-4,4 do begin &  x=analyze_fin2(13,i,/noplot,pitot=1.15) & print,i,stddev(x.wspd[a:b]) & endfor

;------------------------
;Bill made some adjustments to SS and AoA and sent a new file.  Try that here and see if it makes a difference.
a=2000 & b=7000      ;This file has a lot of bad data... I manually trimmed it to match the 'short' version above
;Find pitot adjustment minimum, best= 1.09,
for i=8,12 do begin &  x=analyze_fin2(14,0,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd[a:b],/nan) & endfor

;Find heading adjustment minimum, best=-1
for i=-4,4 do begin &  x=analyze_fin2(14,i,/noplot,pitot=1.09) & print,i,stddev(x.wspd[a:b]) & endfor

;=====================================================================
;Flight 15 11/21/2018 Hebei test case from Bill.  Java miminization tool not working for this.
;**Seems that AoA or SS is messing everything up.  Using wspd3 here instead, which does not consider those and works much better.
a=5500 & b=7000      
;Find pitot adjustment minimum, having trouble with this flight, best 1.09
for i=8,12 do begin &  x=analyze_fin2(15,0.3,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd3[a:b]) & endfor

;Find heading adjustment minimum, best 0.3
for i=-0.5,0.5,0.1 do begin &  x=analyze_fin2(15,i,/noplot,pitot=1.09) & print,i,stddev(x.wspd3[a:b]) & endfor

;=====================================================================
;Flight 16 10/14/2018 India cal flight.  Java miminization tool not working for this.
;**Seems that AoA or SS is messing everything up.  Using wspd3 here instead, which does not consider those and works much better.
a=3700 & b=4700      
;Find pitot adjustment minimum, best 0.89
for i=0,15 do begin &  x=analyze_fin2(16,0.8,/noplot,pitot=1+i/100.0) & print,1+i/100.0,stddev(x.wspd3[a:b]) & endfor

;Find heading adjustment minimum, best 0.8
for i=0.5,1.5,0.1 do begin &  x=analyze_fin2(16,i,/noplot,pitot=0.89) & print,i,stddev(x.wspd3[a:b]) & endfor





