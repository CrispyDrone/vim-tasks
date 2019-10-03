" Tasks plugin
" Language:    Tasks
" Maintainer:  CrispyDrone
" Last Change: Oct 02, 2019
" Version:	   0.18
" URL:         https://github.com/CrispyDrone/vim-tasks

if exists("b:loaded_tasks")
  finish
endif
let b:loaded_tasks = v:true

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
    return v:true
  endif
  return v:false
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
let s:taskStates = { 
      \'done': { 
	\'lineMarker': g:TasksMarkerDone, 
	\'attributes': { 
	  \'project': { 
	    \'function': 'join', 
	    \'arguments': [ 'projects', 'separator' ] 
	  \}, 
	  \'done': {
	    \'function': 'strftime',
	    \'arguments': [ 'dateFormat' ]
	  \}
	\},
	\'next': [ 'none', 'cancelled' ]
      \},
      \'cancelled': { 
	\'lineMarker': g:TasksMarkerCancelled, 
      	\'attributes': { 
	\'project': { 
	  \'function': 'join', 
      	  \'arguments': [ 'projects', 'separator' ] 
      	\}, 
	\'cancelled': {
	  \'function': 'strftime',
      	  \'arguments': [ 'dateFormat' ]
      	\}
	\},
	\'next': [ 'none', 'done' ] 
      \},
      \'none' : {
	\'lineMarker': g:TasksMarkerBase, 
      	\'attributes': {},
      	\'next': [ 'done', 'cancelled' ] 
      	\}
      \}

function! Trim(input_string)
  return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" Returns the project a specified linenumber is associated with.
function! GetProject(lineNumber)
  let l:project = { 'lineNr': 0, 'line': '' }
  let l:lineNumber = a:lineNumber

  if (BelongsToArchive(l:lineNumber))
    return l:project
  endif

  while l:lineNumber > 0
    let l:line = getline(l:lineNumber)
    let l:isMatch = match(l:line, s:regProject)

    if (l:isMatch == -1)
      let l:lineNumber = l:lineNumber - 1
      continue
    endif

    let l:project['lineNr'] = l:lineNumber
    let l:project['line'] = l:line

    break
  endwhile

  return l:project
endfunc

" verifies whether the specified linenumber is part of the archive section.
function! BelongsToArchive(lineNumber)
  let l:lineNumber = a:lineNumber

  while l:lineNumber > 0
    let l:line = Trim(getline(l:lineNumber))

    if (l:line ==# s:archiveSeparator)
      if (Trim(getline(l:lineNumber + 1)) ==# s:regArchive)
	return v:true
      endif
    endif

    let l:lineNumber = l:lineNumber - 1
  endwhile

  return v:false
endfunc

function! NewTask(direction)
  let l:lineNumber = line('.') + a:direction
  let l:project = GetProject(l:lineNumber)

  if l:project['lineNr'] == 0
    return
  endif

  let l:indendation = matchlist(l:project['line'], s:regProject)[1]
  let l:text = g:TasksMarkerBase . ' '

  if a:direction == -1
    exec 'normal O' . l:indendation . l:text
  else
    exec 'normal o' . l:indendation . l:text
  endif

  exec 'normal >>'

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

" returns the start and end cols of an attribute as a dictionary. If the
" attribute doesn't exist, the start and end are -1.
function! GetAttribute(name)
  let l:attribute = { 'start': -1, 'end': -1 }
  let l:rline = getline('.')
  let l:regex = g:TasksAttributeMarker . a:name . '\(([^)]*)\)\='
  let l:attStart = match(l:rline, regex)
  if l:attStart > -1
    let l:attEnd = matchend(l:rline, l:regex)
    let l:attribute['start'] = l:attStart
    let l:attribute['end'] = l:attEnd
  endif
  return l:attribute
endfunc

function! AddAttribute(name, value)
  " at the end of the line, insert in the attribute:
  let l:existingAttribute = GetAttribute(a:name)
  if (l:existingAttribute['start'] == -1)
    let l:attVal = ''
    if a:value != ''
      let l:attVal = '(' . a:value . ')'
    endif
    exec 'normal A ' . g:TasksAttributeMarker . a:name . l:attVal
  endif
endfunc

function! RemoveAttribute(name)
  " if the attribute exists, remove it
  let l:attribute = GetAttribute(a:name)
  let l:attStart = l:attribute['start']
  if l:attStart > -1
    let l:attEnd = l:attribute['end']
    let l:diff = (l:attEnd - l:attStart) + 1
    call cursor(line('.'), l:attStart)
    exec 'normal ' . l:diff . 'dl'
  endif
endfunc

" returns a list of all projects a task is associated with. A task is
" associated with its immediate parent project, but also all parent projects
" of the immediate parent project. A project is a parent of another project
" in case it has a smaller indendation and there is no other project with an
" equal indendation in between both.
function! GetProjects(lineNumber)
  let l:lineNumber = a:lineNumber
  let l:results = []
  let l:project = GetProject(l:lineNumber)

  if (l:project['lineNr'] == 0)
    return l:results
  endif

  let l:projectDepth = strchars(matchlist(l:project['line'], s:regProject)[1])
  let l:parentProjectDepths = [l:projectDepth]
  call add(l:results, GetProjectName(l:project['line']))

  while l:lineNumber > 0
    let l:match = matchlist(getline(l:lineNumber), s:regProject)
    if len(l:match) > 0
      let l:currentDepth = strchars(l:match[1]) 
      if l:currentDepth < l:projectDepth 
	let l:parentProjectAtCurrentDepth = filter(l:parentProjectDepths, 'v:val == ' . l:currentDepth)
	if len(l:parentProjectAtCurrentDepth) == 0
	  call add(l:results, GetProjectName(l:match[0]))
	  call add(l:parentProjectDepths, l:currentDepth)
	endif
      endif
      if indent(l:lineNumber) == 0
	break
      endif
    endif
    let l:lineNumber = l:lineNumber - 1
  endwhile
  return reverse(l:results)
endfunc

" Get the project name from a line containing the project header i.e. trim and
" remove colon.
function! GetProjectName(projectLine)
  let l:projectLine = a:projectLine
  let l:trimmedProjectLine = Trim(l:projectLine)
  return strcharpart(l:trimmedProjectLine, 0, strchars(l:trimmedProjectLine) - 1)
endfunc

function! MarkTaskAs(nextState)
  let l:nextState = a:nextState
  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regMarker)

  if l:isMatch > -1
    let l:lineNumber = line('.')
    let l:projects = GetProjects(l:lineNumber)

    if empty(l:projects)
      return
    endif

    let l:currentState = GetTaskState(l:lineNumber)
    if (l:currentState ==# l:nextState)
      let l:nextState = 'none'
    endif
    
    if has_key(s:taskStates, l:currentState) == v:true
      let l:currentStateOptions = s:taskStates[l:currentState]
      let l:validNextStates = copy(l:currentStateOptions['next'])
      let l:isValidNextState = !empty(filter(l:validNextStates, 'v:val ==# ' . "l:nextState"))
      if (l:isValidNextState == v:true)
	let l:attributesToRemove = keys(l:currentStateOptions['attributes'])

	for l:attribute in l:attributesToRemove
	  call RemoveAttribute(l:attribute)
	endfor

	let l:newLineMarker = s:taskStates[l:nextState]['lineMarker']
	let l:newAttributes = s:taskStates[l:nextState]['attributes']

	call SetLineMarker(l:newLineMarker)
	let l:arguments = { 'projects': l:projects, 'separator': ' \ ', 'dateFormat': s:dateFormat }

	for l:attribute in keys(l:newAttributes)
	  let l:attributeConfiguration = l:newAttributes[l:attribute]
	  let l:attributeFunctionArguments = l:attributeConfiguration['arguments']
	  let l:functionArguments = []
	  for l:attributeFunctionArgument in l:attributeFunctionArguments
	    call add(l:functionArguments, l:arguments[l:attributeFunctionArgument])
	  endfor
	  let l:attributeValue = call(l:attributeConfiguration['function'], l:functionArguments)
	  call AddAttribute(l:attribute, l:attributeValue)
	endfor
      endif
    endif
  endif
endfunc

function! GetTaskState(lineNumber)
  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regMarker)
  let l:state = ''

  if l:isMatch > -1
    let l:isDone = GetAttribute('done')['start'] != -1
    let l:isCancelled = GetAttribute('cancelled')['start'] != -1

    if l:isDone && l:isCancelled
      let l:state = 'invalid'
    elseif l:isDone
      let l:state = 'done'
    elseif l:isCancelled
      let l:state = 'cancelled'
    else
      let l:state = 'none'
    endif
  endif

  return l:state
endfunc

function! TaskComplete()
  call MarkTaskAs('done')
endfunc

function! TaskCancel()
  call MarkTaskAs('cancelled')
endfunc

" Checks whether a specific line has been marked as done or cancelled.
function! IsCompleted(line)
  if match(a:line, s:regDone) > -1
    return v:true
  endif

  if match(a:line, s:regCancelled) > -1
    return v:true
  endif

  return v:false
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

    if l:isCompleted == v:true
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
