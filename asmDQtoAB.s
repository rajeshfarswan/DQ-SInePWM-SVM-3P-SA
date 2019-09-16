/* DQ to modified alpha-beta transfromation */

;this function access integer variables Dvalue and Qvalue in main
;alters integer variables Alpha and Beta
;passing and return arguments are void
;calls assembly function asmINT_MULQ
;all operating vaiables are in q15 value, -0.999 <= value <= +0.999

#include "p30f6010A.inc"

.global _asmDQtoAB

_asmDQtoAB:
disi #0x3FFF
;DQ to alpha
;alpha = (D*C - Q*S);
MOV _Dvalue, W0
;CALL _asmDQ_Limit ;PWM limit
MOV _qCos, W1
CALL _asmINT_MPQ ;Q*Cos
MOV W0,W9

MOV _Qvalue, W0
;CALL _asmDQ_Limit ;PWM limit
MOV _qSin, W1 
CALL _asmINT_MPQ ;D*sine

SUB W9,W0,W7     ;D*C - Q*S
MOV W7, _Alpha   ;copy alpha value
;

;DQ to Beta
;beta =  (D*S + Q*C);
MOV _Dvalue, W0
;CALL _asmDQ_Limit ;PWM limit
MOV _qSin, W1    
CALL _asmINT_MPQ  ;D*Sine
MOV W0,W9

MOV _Qvalue, W0
;CALL _asmDQ_Limit ;PWM limit
MOV _qCos, W1
CALL _asmINT_MPQ  ;Q*Cos

ADD W9,W0,W8      ;D*S + Q*C
MOV W8, _Beta     ;copy beta value
;

disi #0x0000
return 
.end
