
forval i=2(1)30{
	lincom ( (F`i'_ChangeAgeMLowHigh - F`i'_ChangeAgeMLowLow) - (F`i'_ChangeAgeMHighLow - F`i'_ChangeAgeMHighHigh) )
	
	mat b_F`i' = (r(estimate))
	mat se_F`i' = (r(se))
	mat p_F`i' = (r(p))
	mat lo_F`i' = (r(lb))
	mat hi_F`i' = (r(ub))
}

forval i=0(1)30{
	lincom ( (L`i'_ChangeAgeMLowHigh - L`i'_ChangeAgeMLowLow) - (L`i'_ChangeAgeMHighLow - L`i'_ChangeAgeMHighHigh) )
	
	mat b_L`i' = (r(estimate))
	mat se_L`i' = (r(se))
	mat p_L`i' = (r(p))
	mat lo_L`i' = (r(lb))
	mat hi_L`i' = (r(ub))
}

 local dim (`= rowsof(b)',`=colsof(b)') 
  di "`dim'" 

mat b = b_F30\b_F29\b_F28\b_F27\b_F26\b_F25\b_F24\b_F23\b_F22\b_F21\b_F20\b_F19\b_F18\b_F17\b_F16\b_F15\b_F14\b_F13\b_F12\b_F11\b_F10\b_F9\b_F8\b_F7\b_F6\b_F5\b_F4\b_F3\b_F2\0\b_L0\b_L1\b_L2\b_L3\b_L4\b_L5\b_L6\b_L7\b_L8\b_L9\b_L10\b_L11\b_L12\b_L13\b_L14\b_L15\b_L16\b_L17\b_L18\b_L19\b_L20\b_L21\b_L22\b_L23\b_L24\b_L25\b_L26\b_L27\b_L28\b_L29\b_L30
mat se = se_F30\se_F29\se_F28\se_F27\se_F26\se_F25\se_F24\se_F23\se_F22\se_F21\se_F20\se_F19\se_F18\se_F17\se_F16\se_F15\se_F14\se_F13\se_F12\se_F11\se_F10\se_F9\se_F8\se_F7\se_F6\se_F5\se_F4\se_F3\se_F2\0\se_L0\se_L1\se_L2\se_L3\se_L4\se_L5\se_L6\se_L7\se_L8\se_L9\se_L10\se_L11\se_L12\se_L13\se_L14\se_L15\se_L16\se_L17\se_L18\se_L19\se_L20\se_L21\se_L22\se_L23\se_L24\se_L25\se_L26\se_L27\se_L28\se_L29\se_L30
mat p = p_F30\p_F29\p_F28\p_F27\p_F26\p_F25\p_F24\p_F23\p_F22\p_F21\p_F20\p_F19\p_F18\p_F17\p_F16\p_F15\p_F14\p_F13\p_F12\p_F11\p_F10\p_F9\p_F8\p_F7\p_F6\p_F5\p_F4\p_F3\p_F2\0\p_L0\p_L1\p_L2\p_L3\p_L4\p_L5\p_L6\p_L7\p_L8\p_L9\p_L10\p_L11\p_L12\p_13\p_14\p_15\p_16\p_17\p_18\p_19\p_20\p_21\p_22\p_23\p_24\p_25\p_26\p_27\p_28\p_29\p_30
mat lo = lo_F30\lo_F29\lo_F28\lo_F27\lo_F26\lo_F25\lo_F24\lo_F23\lo_F22\lo_F21\lo_F20\lo_F19\lo_F18\lo_F17\lo_F16\lo_F15\lo_F14\lo_F13\lo_F12\lo_F11\lo_F10\lo_F9\lo_F8\lo_F7\lo_F6\lo_F5\lo_F4\lo_F3\lo_F2\0\lo_L0\lo_L1\lo_L2\lo_L3\lo_L4\lo_L5\lo_L6\lo_L7\lo_L8\lo_L9\lo_L10\lo_L11\lo_L12\lo_L13\lo_L14\lo_L15\lo_L16\lo_L17\lo_L18\lo_L19\lo_L20\lo_L21\lo_L22\lo_L23\lo_L24\lo_L25\lo_L26\lo_L27\lo_L28\lo_L29\lo_L30
mat hi = hi_F30\hi_F29\hi_F28\hi_F27\hi_F26\hi_F25\hi_F24\hi_F23\hi_F22\hi_F21\hi_F20\hi_F19\hi_F18\hi_F17\hi_F16\hi_F15\hi_F14\hi_F13\hi_F12\hi_F11\hi_F10\hi_F9\hi_F8\hi_F7\hi_F6\hi_F5\hi_F4\hi_F3\hi_F2\0\hi_L0\hi_L1\hi_L2\hi_L3\hi_L4\hi_L5\hi_L6\hi_L7\hi_L8\hi_L9\hi_L10\hi_L11\hi_L12\hi_L13\hi_L14\hi_L15\hi_L16\hi_L17\hi_L18\hi_L19\hi_L20\hi_L21\hi_L22\hi_L23\hi_L24\hi_L25\hi_L26\hi_L27\hi_L28\hi_L29\hi_L30
mat et = -30\-29\-28\-27\-26\-25\-24\-23\-22\-21\-20\-19\-18\-17\-16\-15\-14\-13\-12\-11\-10\-9\-8\-7\-6\-5\-4\-3\-2\-1\0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30
