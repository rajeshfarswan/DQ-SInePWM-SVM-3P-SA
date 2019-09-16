/*svm PWM generation based on modified alpha-beta to a-b-c*/

/*access integer variables Avalue, Bvalue and Cvalue*/
/*acess and modify duty cycle register 1, 2 and 3 */
/*modifies integer variables Uvalue, Vvalue and Wvalue*/
/*all argumemts are void*/

#include "p30f6010A.inc"

.global _asmSVM

_asmSVM:

disi #0x3FFF

;alpha beta to modified a-b-c
MOV _Alpha, W7 ;copy alpha value //alpha
MOV _Beta, W8  ;copy beta value  //beta

;alpha-beta to modified a
;a = beta;
MOV W8, _Avalue  ;a
;
;alpha-beta to modified b
;b = (1/2)*beta + (sqrt(3)/2)*alpha;
MOV #0x6eda, W0  ;(sqrt(3)/2)
MOV W7, W1
CALL _asmINT_MPQ ;(sqrt(3)/2)*alpha
MOV W0,W9

MOV #0x4000, W0  ;(1/2)
MOV W8,W1
CALL _asmINT_MPQ ;(1/2)*beta

ADD W9,W0,W0     ;(1/2)*beta + (sqrt(3)/2)*alpha
MOV W0, _Bvalue  ;b
;
;alpha-beta to modified c
;c = (1/2)*beta - (sqrt(3)/2)*alpha;
MOV #0x9126, W0  ;(-sqrt(3)/2)
MOV W7, W1
CALL _asmINT_MPQ ;(-sqrt(3)/2)*alpha
MOV W0,W9

MOV #0x4000, W0  ;(1/2)
MOV W8,W1
CALL _asmINT_MPQ ;(1/2)*beta

ADD W9,W0,W0     ;(1/2)*beta + (-sqrt(3)/2)*alpha;
MOV W0, _Cvalue  ;c  
;alpha beta to modified a-b-b
;/////////////////////////////////////////////////////

;alpha-beta to modified u-v-w for sector identification
;
;alpha-beta to modified Uvalue
;u = beta;
MOV W8, _Uvalue ;u
;
;alpha-beta to modified Vvalue
;v = (-1/2)*beta + (sqrt(3)/2)*alpha;
MOV #0x6eda, W0   ;(sqrt(3)/2)
MOV W7, W1
CALL _asmINT_MPQ  ;(sqrt(3)/2)*alpha
MOV W0,W9

MOV #0x4000, W0   ;(1/2)
MOV W8,W1
CALL _asmINT_MPQ  ;(1/2)*beta

SUB W9,W0,W0      ;(-1/2)*beta + (sqrt(3)/2)*alpha
MOV W0, _Vvalue   ;v
;
;alpha-beta to modified Wvalue
;w = (-1/2)*beta - (sqrt(3)/2)*alpha;
MOV #0x9126, W0   ;(-sqrt(3)/2)
MOV W7, W1
CALL _asmINT_MPQ  ;(-sqrt(3)/2)*alpha
MOV W0,W9

MOV #0xc000, W0   ;(-1/2)
MOV W8,W1
CALL _asmINT_MPQ  ;(-1/2)*beta

ADD W9,W0,W0      ;(-1/2)*beta + (-sqrt(3)/2)*alpha
MOV W0, _Wvalue   ;w
;alpha beta to modified u-v-w
;///////////////////////////////////////////////////

;determine sector from u-v-w
;
MOV _Wvalue,W0
CP0 W0             ;compare w with 0
BRA GT,Sector_345  ;go to positive zone if greater
BRA Sector_126     ;else go to negative zone
BRA Sector7        ;else return
;determine sector from uvw

;positive sector zone
Sector_345:
MOV _Vvalue,W0
CP0 W0            ;compare v with 0
BRA GT,Sector5    ;go to sector 5 if greater
MOV _Uvalue,W0    
CP0 W0            ;else compare u with 0
BRA LE,Sector4    ;got to sector 4 if less
BRA Sector3       ;else go to sector 3
BRA Sector7       ;else return
;
;negative sector zone
Sector_126:
MOV _Vvalue,W0
CP0 W0            ;compare v with 0
BRA LE,Sector2    ;go to sector 2 if less
MOV _Uvalue,W0
CP0 W0            ;else compare u with 0
BRA LE,Sector6    ;go to sector 6 if less
BRA Sector1       ;else go to sector 1
BRA Sector7       ;else return
;
;/////////////////////////////////////////////////

;sector definitations and t1 and t2 calculation for all sectors
;
Sector1:           ;SECTOR1 /////////////////////
MOV _Avalue,W7     ;t1 = a
MOV _Cvalue,W0 
CALL _asmCOM       ;comliment c value
MOV W0,W8          ;t2 = -c

CALL _asmDutyCycle ;generate on-time w1, w2, w3 for sector 1

MOV W3,PDC1 ;3     ;duty 1 = t3
MOV W2,PDC2 ;2     ;duty 2 = t2
MOV W1,PDC3 ;1     ;duty 3 = t1
MOV #0x0001,W0
MOV W0,_sect       ;update sector value 
BRA Sector7

;
Sector2:           ;SECTOR2 ////////////////////
MOV _Bvalue,W7     ;t1 = b
MOV _Cvalue,W8     ;t2 = c

CALL _asmDutyCycle ;generate on-time w1, w2, w3 for sector 2

MOV W2,PDC1 ;2     ;duty 1 = t2
MOV W3,PDC2 ;3     ;duty 2 = t3
MOV W1,PDC3 ;1     ;duty 3 = t1
MOV #0x0002,W0
MOV W0,_sect       ;update sector value 
BRA Sector7
;
Sector3:           ;SECTOR3 ///////////////////
MOV _Bvalue,W0
CALL _asmCOM
MOV W0,W7          ;t1 = -b
MOV _Avalue,W8     ;t2 = a

CALL _asmDutyCycle ;generate on-time w1, w2, w3 for sector 3

MOV W1,PDC1 ;1     ;duty 1 = t1
MOV W3,PDC2 ;3     ;duty 2 = t3
MOV W2,PDC3 ;2     ;duty 3 = t2
MOV #0x0003,W0
MOV W0,_sect       ;update sector value 
BRA Sector7
;
Sector4:           ;SECTOR4 ///////////////////
MOV _Cvalue,W7     ;t1 = c
MOV _Avalue,W0     
CALL _asmCOM       ;t2 = -a
MOV W0,W8        
  
CALL _asmDutyCycle ;generate on-time w1, w2, w3 for sector 4

MOV W1,PDC1 ;1     ;duty 1 = t1
MOV W2,PDC2 ;2     ;duty 2 = t2
MOV W3,PDC3 ;3     ;duty 3 = t3
MOV #0x0004,W0
MOV W0,_sect       ;update sector value 
BRA Sector7
;
Sector5:           ;SECTOR5 ///////////////////
MOV _Cvalue,W0
CALL _asmCOM
MOV W0,W7          ;t1 = -c
MOV _Bvalue,W0
CALL _asmCOM
MOV W0,W8          ;t2 = -b

CALL _asmDutyCycle ;generate on-time w1, w2, w3 for sector 5

MOV W2,PDC1 ;2     ;duty 1 = t2
MOV W1,PDC2 ;1     ;duty 2 = t1
MOV W3,PDC3 ;3     ;duty 3 = t3
MOV #0x0005,W0
MOV W0,_sect       ;update sector value 
BRA Sector7
;
Sector6:           ;SECTOR6 ////////////////////
MOV _Avalue,W0
CALL _asmCOM
MOV W0,W7          ;t2 = -a
MOV _Bvalue,W8     ;t1 = b

CALL _asmDutyCycle ;generate on-time w1, w2, w3 for sector 6

MOV W3,PDC1 ;3      ;duty 1 = t3
MOV W1,PDC2 ;1      ;duty 2 = t1
MOV W2,PDC3 ;2      ;duty 3 = t2
MOV #0x0006,W0
MOV W0,_sect        ;update sector value 
BRA Sector7
;///////////////////////////////////////////////

;duty cycle generation variables w1,w2 and w3
;
_asmDutyCycle:
MOV #3554,W9      ;copy T ; total time period of PWM 
ADD W7,W8,W0      ;alpha + beta
SUB W9,W0,W0      ;T- (alpha + beta)
MOV #16384,W1     ;(1/2)
CALL _asmINT_MPQ  ;(T- alpha - beta)/2
;
MOV W0,W1         ;t1 = (T- alpha - beta)/2

ADD W1,W7,W2      ;t2 = t1 + alpha

ADD W2,W8,W3      ;t3 = t2 + beta 

return
;
;routine to generate negative value of input argument
_asmCOM:
CLR W1
SUB W1,W0,W0
return
;

Sector7:
disi #0x0000
return 
.end
