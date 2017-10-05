; docformat = 'rst'
;
; NAME:
;       MrWindow_Resolve_All
;
;*****************************************************************************************
;   Copyright (c) 2017, Matthew Argall                                                   ;
;   All rights reserved.                                                                 ;
;                                                                                        ;
;   Redistribution and use in source and binary forms, with or without modification,     ;
;   are permitted provided that the following conditions are met:                        ;
;                                                                                        ;
;       * Redistributions of source code must retain the above copyright notice,         ;
;         this list of conditions and the following disclaimer.                          ;
;       * Redistributions in binary form must reproduce the above copyright notice,      ;
;         this list of conditions and the following disclaimer in the documentation      ;
;         and/or other materials provided with the distribution.                         ;
;       * Neither the name of the <ORGANIZATION> nor the names of its contributors may   ;
;         be used to endorse or promote products derived from this software without      ;
;         specific prior written permission.                                             ;
;                                                                                        ;
;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY  ;
;   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES ;
;   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT  ;
;   SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,       ;
;   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED ;
;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR   ;
;   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     ;
;   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN   ;
;   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  ;
;   DAMAGE.                                                                              ;
;*****************************************************************************************
;
; PURPOSE:
;+
;   Resolve all dependencies of the MrWindow routines.
;
; :Keywords:
;       RESOLVE_CLASS:      out, optional, type=strarr
;                           Names of the classes to be resolved.
;       RESOLVE_PROCEDURE:  out, optional, type=strarr
;                           Names of the procedures to be resolved.
;       RESOLVE_FUNCTION:   out, optional, type=strarr
;                           Names of the functions to be resovled.
;       _REF_EXTRA:         out, optional, type=strarr
;                           Any keyword accepted by MrResolve_All is also accepted here.
;
; :Author:
;   Matthew Argall::
;       University of New Hampshire
;       Morse Hall, Room 348
;       8 College Rd.
;       Durham, NH, 03824
;       matthew.argall@unh.edu
;
; :History:
;   Change History::
;       2017/04/03  -   Written by Matthew Argall
;-
pro MrWindow_Resolve_All, $
RESOLVE_CLASS=resolve_class, $
RESOLVE_FUN=resolve_fun, $
RESOLVE_PRO=resolve_pro, $
_REF_EXTRA=extra
	compile_opt idl2
	on_error, 2

;-----------------------------------------------------
; Resolve Routines \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

	;Routines to be resolved
	class = ['fsc_psconfig', $
	         'linkedlist', $
	         'mrabstractcdf', $
	         'mrcursor', $
	         'mrmanipulate', $
	         'mrsaveas', $
	         'mrzoom', $
	         'mrsaveas', $
	         'mrgrlayout', $
	         'mrplotmanager', $
	         'mrwindow_container', $
	         'mrwindow', $
	         'mrdatacoords', $
	         'mrgraphicskeywords', $
	         'mrgratom', $
	         'mrgrdataatom', $
	         'mrlayout', $
	         'mraxis', $
	         'mrcircle', $
	         'mrcolorbar', $
	         'mrcolorpalette', $
	         'mrcontour', $
	         'mrimage', $
	         'mrlegend', $
	         'mrplot', $
	         'mrplots', $
	         'mrpolygon', $
	         'mrtext', $
	         'mrvector']
	
	funs  = ['getmrwindows', $
	         'mraxis', $
	         'mrcolorbar', $
	         'mrcontour', $
	         'mrcorrplot', $
	         'mrdistfn', $
	         'mrimage', $
	         'mrlegend', $
	         'mrplot', $
	         'mrplots', $
	         'mrpolygon', $
	         'mrtext', $
	         'mrvector', $
	         'mrwindow', $
	         'time_labels']

	;Resolve routines
	MrResolve_All, RESOLVE_CLASS     = class, $
	               RESOLVE_FUNCTION  = funs, $
	               RESOLVE_PROCEDURE = pros, $
	               _STRICT_EXTRA     = extra
end