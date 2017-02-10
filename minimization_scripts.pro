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



