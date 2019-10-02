" Tasks plugin
" Language:    Tasks
" Maintainer:  CrispyDrone
" Last Change: Oct 02, 2019
" Version:	   0.14
" URL:         https://github.com/CrispyDrone/vim-tasks

if exists("b:loaded_tasks")
  finish
endif
let b:loaded_tasks = 1

" MAPPINGS
nnoremap <buffer> <localleader>n :call NewTask(1)<cr>
nnoremap <buffer> <localleader>N :call NewTask(-1)<cr>
nnoremap <buffer> <localleader>d :call TaskComplete()<cr>
nnoremap <buffer> <localleader>x :call TaskCancel()<cr>
nnoremap <buffer> <localleader>a :call TasksArchive()<cr>

" GLOBALS

" Helper for initializing defaults
" (https://github.com/scrooloose/nerdtree/blob/master/plugin/NERD_tree.vim#L39)
function! s:initVariable(var, value)
  if !exists(a:var)
    exec 'let ' . a:var . ' = ' . "'" . substitute(a:value, "'", "''", "g") . "'"
    return 1
  endif
  return 0
endfunc

call s:initVariable('g:TasksMarkerBase', '☐')
call s:initVariable('g:TasksMarkerDone', '✔')
call s:initVariable('g:TasksMarkerCancelled', '✘')
call s:initVariable('g:TasksDateFormat', '%Y-%m-%d %H:%M')
call s:initVariable('g:TasksAttributeMarker', '@')
call s:initVariable('g:TasksArchiveSeparator', '＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿')
call s:initVariable('g:TasksHeaderArchive', 'Archive')

let b:regesc = '[]()?.*@='

" LOCALS
let s:regMarker = join([escape(g:TasksMarkerBase, b:regesc), escape(g:TasksMarkerDone, b:regesc), escape(g:TasksMarkerCancelled, b:regesc)], '\|')
let s:regProject = '^\(\s*\)\(\(.*' . s:regMarker . '.*\)\@!.\)\+:\s*$'
let s:regDone = g:TasksAttributeMarker . 'done'
let s:regCancelled = g:TasksAttributeMarker . 'cancelled'
let s:regAttribute = g:TasksAttributeMarker . '\w\+\(([^)]*)\)\='
let s:dateFormat = g:TasksDateFormat
let s:archiveSeparator = g:TasksArchiveSeparator
let s:regArchive = g:TasksHeaderArchive . ':'

function! Trim(input_string)
  return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" Checks whether the specified linenumber is associated with a project.
function! BelongsToProject(lineNumber)
  let l:lineNumber = a:lineNumber

  if (BelongsToArchive(l:lineNumber))
    return 0
  endif

  while l:lineNumber > 0
    let l:line = getline(l:lineNumber)
    let l:isMatch = match(l:line, s:regProject)

    if (l:isMatch == -1)
      let l:lineNumber = l:lineNumber - 1
      continue
    endif

    return 1
  endwhile

  return 0
endfunc

function! BelongsToArchive(lineNumber)
  let l:lineNumber = a:lineNumber

  while l:lineNumber > 0
    let l:line = Trim(getline(l:lineNumber))

    if (l:line ==# s:archiveSeparator)
      if (Trim(getline(l:lineNumber + 1)) ==# s:regArchive)
	return 1
      endif
    endif

    let l:lineNumber = l:lineNumber - 1
  endwhile

  return 0
endfunc

function! NewTask(direction)
  let l:lineNumber = line('.') + a:direction

  if BelongsToProject(l:lineNumber) == 0
    echoerr "No associated project."
    return 1
  endif

  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regProject)
  let l:text = g:TasksMarkerBase . ' '

  if a:direction == -1
    exec 'normal O' . l:text
  else
    exec 'normal o' . l:text
  endif

  if l:isMatch > -1
    exec 'normal >>'
  endif

  startinsert!
endfunc

function! SetLineMarker(marker)
  " if there is a marker, swap it out.
  " If there is no marker, add it in at first non-whitespace
  let l:line = getline('.')
  let l:markerMatch = match(l:line, s:regMarker)
  if l:markerMatch > -1
    call cursor(line('.'), l:markerMatch + 1)
    exec 'normal R' . a:marker
  endif
endfunc

function! AddAttribute(name, value)
  " at the end of the line, insert in the attribute:
  let l:attVal = ''
  if a:value != ''
    let l:attVal = '(' . a:value . ')'
  endif
  exec 'normal A ' . g:TasksAttributeMarker . a:name . l:attVal
endfunc

function! RemoveAttribute(name)
  " if the attribute exists, remove it
  let l:rline = getline('.')
  let l:regex = g:TasksAttributeMarker . a:name . '\(([^)]*)\)\='
  let l:attStart = match(l:rline, regex)
  if l:attStart > -1
    let l:attEnd = matchend(l:rline, l:regex)
    let l:diff = (l:attEnd - l:attStart) + 1
    call cursor(line('.'), l:attStart)
    exec 'normal ' . l:diff . 'dl'
  endif
endfunc

function! GetProjects()
  " read from current line upwards, seeking all project matches
  " and adding them to a list
  let l:lineNr = line('.') - 1
  let l:results = []
  while l:lineNr > 0
    let l:match = matchstr(getline(l:lineNr), s:regProject)
    if len(l:match)
      call add(l:results, Trim(strpart(l:match, 0, len(l:match) - 1)))
      if indent(l:lineNr) == 0
	break
      endif
    endif
    let l:lineNr = l:lineNr - 1
  endwhile
  return reverse(l:results)
endfunc

function! TaskComplete()
  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regMarker)
  let l:doneMatch = match(l:line, s:regDone)
  let l:cancelledMatch = match(l:line, s:regCancelled)

  if l:isMatch > -1
    if l:doneMatch > -1
      " this task is done, so we need to remove the marker and the
      " @done/@project
      call SetLineMarker(g:TasksMarkerBase)
      call RemoveAttribute('done')
      call RemoveAttribute('project')
    else
      if l:cancelledMatch > -1
	" this task was previously cancelled, so we need to swap the marker
	" and just remove the @cancelled first
	call RemoveAttribute('cancelled')
	call RemoveAttribute('project')
      endif
      " swap out the marker, add the @done, find the projects and add @project
      let l:projects = GetProjects()
      call SetLineMarker(g:TasksMarkerDone)
      call AddAttribute('done', strftime(s:dateFormat))
      call AddAttribute('project', join(l:projects, ' / '))
    endif
  endif
endfunc

function! TaskCancel()
  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regMarker)
  let l:doneMatch = match(l:line, s:regDone)
  let l:cancelledMatch = match(l:line, s:regCancelled)

  if l:isMatch > -1
    if l:cancelledMatch > -1
      " this task is done, so we need to remove the marker and the
      " @done/@project
      call SetLineMarker(g:TasksMarkerBase)
      call RemoveAttribute('cancelled')
      call RemoveAttribute('project')
    else
      if l:doneMatch > -1
	" this task was previously cancelled, so we need to swap the marker
	" and just remove the @cancelled first
	call RemoveAttribute('done')
	call RemoveAttribute('project')
      endif
      " swap out the marker, add the @done, find the projects and add @project
      let l:projects = GetProjects()
      call SetLineMarker(g:TasksMarkerCancelled)
      call AddAttribute('cancelled', strftime(s:dateFormat))
      call AddAttribute('project', join(l:projects, ' / '))
    endif
  endif
endfunc

" Checks whether a specific line has been marked as done or cancelled.
function! IsCompleted(line)
  if match(a:line, s:regDone) > -1
    return 1
  endif

  if match(a:line, s:regCancelled) > -1
    return 1
  endif

  return 0
endfunc

function! TasksArchive()
  " go over every line. Compile a list of all cancelled or completed items
  " until the end of the file is reached or the archive project is
  " detected, whicheved happens first.
  let l:archiveLine = -1
  let l:completedTasks = []
  let l:lineNr = 0
  let l:lastLine = line('$')
  while l:lineNr < l:lastLine
    let l:line = getline(l:lineNr)
    let l:isCompleted = IsCompleted(l:line)
    let l:projectMatch = matchstr(l:line, s:regProject)

    if l:isCompleted == 1
      call add(l:completedTasks, [l:lineNr, Trim(l:line)])
    endif

    if l:projectMatch > -1 && Trim(l:line) == 'Archive:'
      let l:archiveLine = l:lineNr
      break
    endif

    let l:lineNr = l:lineNr + 1
  endwhile

  if l:archiveLine == -1
    " no archive found yet, so let's stick one in at the very bottom
    exec '%s#\($\n\s*\)*\%$##'
    exec 'normal Go'
    exec 'normal o' . g:TasksArchiveSeparator
    exec 'normal oArchive:'
    let l:archiveLine = line('.')
  endif

  call cursor(l:archiveLine, 0)

  for [l:lineNr, l:line] in l:completedTasks
    exec 'normal o' . l:line
    if indent(line('.')) == 0
      exec 'normal >>'
    endif
  endfor

  for [l:lineNr, l:line] in reverse(l:completedTasks)
    call cursor(l:lineNr, 0)
    exec 'normal "_dd'
  endfor
endfunc
