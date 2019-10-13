" Tasks syntax
" Language:    Tasks
" Maintainer:  CrispyDrone
" Previous Maintainer: Chris Rolfs
" Last Change: Oct 4, 2019
" Version:	   0.20
" URL:         https://github.com/CrispyDrone/vim-tasks

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'tasks'
endif

silent! syntax include @markdown syntax/markdown.vim
unlet! b:current_syntax

syn case match
syn sync fromstart

let b:regesc = '[]()?.*@=\'

function! s:CreateMatch(name, regex)
  exec 'syn match ' . a:name . ' "' . a:regex . '" contained'
endfunc


call s:CreateMatch('tMarker', '^\s*' . escape(g:TasksMarkerBase, b:regesc))
call s:CreateMatch('tMarkerCancelled', '^\s*' . escape(g:TasksMarkerCancelled, b:regesc))
call s:CreateMatch('tMarkerComplete', '^\s*' . escape(g:TasksMarkerDone, b:regesc))

exec 'syn match tAttribute "' . g:TasksAttributeMarker . '\w\+\(([^)]*)\)\=" contained'
exec 'syn match tAttributeCompleted "' . g:TasksAttributeMarker . '\w\+\(([^)]*)\)\=" contained'
exec 'syn match tLowPriority "' . g:TasksAttributeMarker . 'priority(low)" contained'
exec 'syn match tMediumPriority "' . g:TasksAttributeMarker . 'priority(medium)" contained'
exec 'syn match tHighPriority "' . g:TasksAttributeMarker . 'priority(high)" contained'
exec 'syn match tCriticalPriority "' . g:TasksAttributeMarker . 'priority(critical)" contained'

syn region tTask start=/^\s*/ end=/$/ oneline keepend contains=tMarker,tAttribute, tLowPriority, tMediumPriority, tHighPriority, tCriticalPriority
exec 'syn region tTaskDone start="^[\s]*.*'.g:TasksAttributeMarker.'done" end=/$/ oneline contains=tMarkerComplete,tAttributeCompleted'
exec 'syn region tTaskCancelled start="^[\s]*.*'.g:TasksAttributeMarker.'cancelled" end=/$/ oneline contains=tMarkerCancelled,tAttributeCompleted'
syn match tProject "^\s*.*:$"

hi def link tMarker Comment
hi def link tMarkerComplete String
hi def link tMarkerCancelled Statement
hi def link tAttribute Special
hi def link tAttributeCompleted Function
hi def link tTaskDone Comment
hi def link tTaskCancelled Comment
hi def link tProject Constant
hi def link tLowPriority Statement
hi def link tMediumPriority Type
hi def link tHighPriority PreProc
hi def link tCriticalPriority Todo
