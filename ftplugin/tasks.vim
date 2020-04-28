" Tasks plugin
" Language:    Tasks
" Maintainer:  CrispyDrone
" Previous Maintainer:  Chris Rolfs
" Last Change: April 29, 2020
" Version:	   0.12.2
" URL:         https://github.com/CrispyDrone/vim-tasks

if exists("b:loaded_tasks")
  finish
endif
let b:loaded_tasks = v:true

" MAPPINGS
nnoremap <buffer> <Plug>(TasksNewTaskUp) :call <SID>NewTask(-1)<CR>
nnoremap <buffer> <Plug>(TasksNewTaskDown) :call <SID>NewTask(1)<CR>
nnoremap <buffer> <Plug>(TasksBeginTask) :call <SID>TaskBegin()<CR>
nnoremap <buffer> <Plug>(TasksCompleteTask) :call <SID>TaskComplete()<CR>
nnoremap <buffer> <Plug>(TasksCancelTask) :call <SID>TaskCancel()<CR>
nnoremap <buffer> <Plug>(TasksArchiveTasks) :call <SID>TasksArchive()<CR>
nnoremap <buffer> <Plug>(TasksMarkPriorityLow) :call <SID>SetAttribute('priority', 'low')<CR>
nnoremap <buffer> <Plug>(TasksMarkPriorityMedium) :call <SID>SetAttribute('priority', 'medium')<CR>
nnoremap <buffer> <Plug>(TasksMarkPriorityHigh) :call <SID>SetAttribute('priority', 'high')<CR>
nnoremap <buffer> <Plug>(TasksMarkPriorityCritical) :call <SID>SetAttribute('priority', 'critical')<CR>
nnoremap <buffer> <Plug>(TasksSortTasks) :call <SID>SortTasks()<CR>
nnoremap <buffer> <Plug>(TasksToggleTask) :call <SID>ToggleTask(-1)<CR>
nnoremap <buffer> <Plug>(TasksToggleAndClearTask) :call <SID>ToggleTask(1)<CR>
nnoremap <buffer> <Plug>(TasksSetAttribute) :call <SID>SetAttributeInteractive()<CR>
nnoremap <buffer> <Plug>(TasksRemoveAttribute) :call <SID>RemoveAttribute(line('.'), input('name:'))<CR>

if !hasmapto('<Plug>(TasksNewTaskDown)')
  nmap <buffer> <localleader>n <Plug>(TasksNewTaskDown)
endif

if !hasmapto('<Plug>(TasksNewTaskUp)')
  nmap <buffer> <localleader>N <Plug>(TasksNewTaskUp)
endif

if !hasmapto('<Plug>(TaskBeginTask)')
  nmap <buffer> <localleader>b <Plug>(TasksBeginTask)
endif

if !hasmapto('<Plug>(TasksCompleteTask)')
  nmap <buffer> <localleader>d <Plug>(TasksCompleteTask)
endif

if !hasmapto('<Plug>(TasksCancelTask)')
  nmap <buffer> <localleader>x <Plug>(TasksCancelTask)
endif

if !hasmapto('<Plug>(TasksArchiveTasks)')
  nmap <buffer> <localleader>A <Plug>(TasksArchiveTasks)
endif

if !hasmapto('<Plug>(TasksMarkPriorityLow)')
  nmap <buffer> <localleader>ml <Plug>(TasksMarkPriorityLow)
endif

if !hasmapto('<Plug>(TasksMarkPriorityMedium)')
  nmap <buffer> <localleader>mm <Plug>(TasksMarkPriorityMedium)
endif

if !hasmapto('<Plug>(TasksMarkPriorityHigh)')
  nmap <buffer> <localleader>mh <Plug>(TasksMarkPriorityHigh)
endif

if !hasmapto('<Plug>(TasksMarkPriorityCritical)')
  nmap <buffer> <localleader>mc <Plug>(TasksMarkPriorityCritical)
endif

if !hasmapto('<Plug>(TasksSortTasks)')
  nmap <buffer> <localleader>S <Plug>(TasksSortTasks)
endif

if !hasmapto('<Plug>(TasksToggleTask)')
  nmap <buffer> <localleader>t <Plug>(TasksToggleTask)
endif

if !hasmapto('<Plug>(TasksToggleAndClearTask)')
  nmap <buffer> <localleader>T <Plug>(TasksToggleAndClearTask)
endif

if !hasmapto('<Plug>(TasksSetAttribute)')
  nmap <buffer> <localleader>a <Plug>(TasksSetAttribute)
endif

if !hasmapto('<Plug>(TasksRemoveAttribute)')
  nmap <buffer> <localleader>r <Plug>(TasksRemoveAttribute)
endif

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
call s:initVariable('g:TasksMarkerInProgress', '»')
call s:initVariable('g:TasksMarkerDone', '✓')
call s:initVariable('g:TasksMarkerCancelled', '✘')
call s:initVariable('g:TasksDateFormat', '%Y-%m-%d %H:%M')
call s:initVariable('g:TasksAttributeMarker', '@')
call s:initVariable('g:TasksArchiveSeparator', '＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿')
call s:initVariable('g:TasksHeaderArchive', 'Archive')

let b:regesc = '[]()?.*@=\'

" LOCALS
let s:regMarker = join([escape(g:TasksMarkerBase, b:regesc), escape(g:TasksMarkerInProgress, b:regesc), escape(g:TasksMarkerDone, b:regesc), escape(g:TasksMarkerCancelled, b:regesc)], '\|')
let s:regProject = '^\(\s*\)\(\(.*' . s:regMarker . '.*\)\@!.\)\+:\s*$'
let s:regTask = '^\(\s*\)\(' . s:regMarker . '\) \=\(.*\)$'
let s:regDone = g:TasksAttributeMarker . 'done'
let s:regCancelled = g:TasksAttributeMarker . 'cancelled'
let s:regAttribute = g:TasksAttributeMarker . '\w\+\(([^)]*)\)\='
let s:dateFormat =  g:TasksDateFormat
let s:archiveSeparator = g:TasksArchiveSeparator
let s:regArchive = g:TasksHeaderArchive . ':'
let s:markerToTaskState = { g:TasksMarkerInProgress: 'inprogress', g:TasksMarkerDone: 'done', g:TasksMarkerCancelled: 'cancelled', g:TasksMarkerBase: 'none'}
let s:taskStates = { 
      \'inprogress': {
        \'lineMarker': g:TasksMarkerInProgress,
        \'attributes': {
          \'started': {
            \'function': 's:AddStartedAttribute',
            \'arguments': ['dateFormat' ],
	    \'add': { prevState -> v:true },
	    \'remove': { nextState, forceRemove -> v:true }
          \},
	  \'worked': {
            \'function': 's:CalculateWorkedTime',
            \'arguments': [ 'started', 'worked', 'dateFormat' ],
	    \'add': { prevState -> v:false },
	    \'remove': { nextState, forceRemove -> forceRemove == v:true }
          \}
        \},
        \'next': [ 'none', 'done', 'cancelled' ]
      \},
      \'done': { 
	\'lineMarker': g:TasksMarkerDone, 
	\'attributes': { 
	  \'project': { 
	    \'function': 'join', 
	    \'arguments': [ 'projects', 'separator' ],
	    \'add': { prevState -> v:true },
	    \'remove': { nextState, forceRemove -> v:true }
	  \}, 
	  \'done': {
	    \'function': 'strftime',
	    \'arguments': [ 'dateFormat' ],
	    \'add': { prevState -> v:true },
	    \'remove': { nextState, forceRemove -> v:true }
	  \},
	  \'worked': {
	    \'function': 's:CalculateWorkedTime',
      	    \'arguments': [ 'started', 'worked', 'dateFormat' ],
	    \'add': { prevState -> prevState == 'inprogress' },
	    \'remove': { nextState, forceRemove -> forceRemove == v:true }
	  \}
	\},
	\'next': [ 'none', 'inprogress', 'cancelled' ]
      \},
      \'cancelled': { 
	\'lineMarker': g:TasksMarkerCancelled, 
      	\'attributes': { 
	  \'project': { 
	    \'function': 'join', 
      	    \'arguments': [ 'projects', 'separator' ],
	    \'add': { prevState -> v:true },
	    \'remove': { nextState, forceRemove -> v:true }
	  \}, 
	  \'cancelled': {
	    \'function': 'strftime',
      	    \'arguments': [ 'dateFormat' ],
	    \'add': { prevState -> v:true },
	    \'remove': { nextState, forceRemove -> v:true }
	  \},
	  \'worked': {
	    \'function': 's:CalculateWorkedTime',
      	    \'arguments': [ 'started', 'worked', 'dateFormat' ],
	    \'add': { prevState -> prevState == 'inprogress' },
	    \'remove': { nextState, forceRemove -> forceRemove == v:true }
	  \}
	\},
	\'next': [ 'none', 'inprogress', 'done' ] 
      \},
      \'none' : {
	\'lineMarker': g:TasksMarkerBase, 
      	\'attributes': {
	  \'worked': {
	    \'function': 's:CalculateWorkedTime',
      	    \'arguments': [ 'started', 'worked', 'dateFormat' ],
	    \'add': { prevState -> v:false },
	    \'remove': { nextState, forceRemove -> forceRemove == v:true }
	  \}
        \},
      	\'next': [ 'inprogress', 'done', 'cancelled' ] 
      	\}
      \}

function! s:Trim(input_string)
  return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" Returns the project a specified linenumber is associated with.
function! s:GetProject(lineNumber)
  let l:project = { 'lineNr': 0, 'line': '' }
  let l:lineNumber = a:lineNumber

  if (s:BelongsToArchive(l:lineNumber))
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
function! s:BelongsToArchive(lineNumber)
  let l:lineNumber = a:lineNumber

  while l:lineNumber > 0
    let l:line = s:Trim(getline(l:lineNumber))

    if (l:line ==# s:archiveSeparator)
      if (s:Trim(getline(l:lineNumber + 1)) ==# s:regArchive)
	return v:true
      endif
    endif

    let l:lineNumber = l:lineNumber - 1
  endwhile

  return v:false
endfunc

function! s:NewTask(direction)
  let l:lineNumber = line('.') + min([a:direction, 0])
  let l:project = s:GetProject(l:lineNumber)

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

function! s:SetLineMarker(marker)
  " if there is a marker, swap it out.
  " If there is no marker, add it in at first non-whitespace
  let l:line = getline('.')
  let l:isTask = match(l:line, s:regTask) > -1
  if l:isTask == v:true
    let l:markerMatch = match(l:line, s:regMarker)
    if l:markerMatch > -1
      call cursor(line('.'), l:markerMatch + 1)
      exec 'normal R' . a:marker
    endif
  endif
endfunc

" returns the { name, value, start, end } (start and end are cols) of an attribute as a dictionary. If the
" attribute doesn't exist, the start and end are -1.
function! s:GetAttribute(lineNumber, name)
  let l:attribute = { 'name': '', 'start': -1, 'end': -1, 'value': '' }
  let l:name = s:Trim(a:name)

  if len(l:name) == 0
    return l:attribute
  endif

  let l:rline = getline(a:lineNumber)
  let l:regex = g:TasksAttributeMarker . escape(l:name, b:regesc) . '\((\([^)]*\))\)\='
  let l:attStart = match(l:rline, l:regex)
  if l:attStart > -1
    let l:attEnd = matchend(l:rline, l:regex)
    let l:attribute['name'] = l:name
    let l:attribute['start'] = l:attStart
    let l:attribute['end'] = l:attEnd
    let l:diff = (l:attEnd - l:attStart) + 1
    let l:value = matchlist(l:rline, l:regex)[2]
    let l:attribute['value'] = l:value
  endif
  return l:attribute
endfunc

function! s:AddAttribute(lineNumber, name, value)
  " at the end of the line, insert in the attribute:
  let l:existingAttribute = s:GetAttribute(a:lineNumber, a:name)
  if (l:existingAttribute['start'] == -1)
    let l:attVal = ''
    if a:value != ''
      let l:attVal = '(' . a:value . ')'
    endif
    exec 'normal A ' . g:TasksAttributeMarker . a:name . l:attVal
  endif
endfunc

function! s:RemoveAttribute(lineNumber, name)
  " if the attribute exists, remove it
  let l:attribute = s:GetAttribute(a:lineNumber, a:name)
  let l:attStart = l:attribute['start']
  if l:attStart > -1
    let l:cursorPosition = getcurpos()
    let l:attEnd = l:attribute['end']
    let l:diff = (l:attEnd - l:attStart) + 1
    call cursor(line('.'), l:attStart)
    exec 'normal ' . l:diff . 'dl'
    call setpos('.', l:cursorPosition)
  endif
endfunc

function! s:SetAttribute(name, value)
  let l:name = s:Trim(a:name)

  if len(l:name) == 0
    return
  endif

  let l:istask = match(getline('.'), s:regTask) > -1
  if l:istask == v:false
    return
  endif

  let l:cursorPosition = getcurpos()
  let l:lineNr = line('.')
  let l:attribute = s:GetAttribute(l:lineNr, l:name)
  if l:attribute['start'] == -1
    call s:AddAttribute(l:lineNr, l:name, a:value)
  else
    call s:RemoveAttribute(l:lineNr, l:name)
    if l:attribute['value'] !=# a:value
      call s:AddAttribute(l:lineNr, l:name, a:value)
    endif
  endif
  call setpos('.', l:cursorPosition)
endfunc

function! s:SetAttributeInteractive()
  let l:istask = match(getline('.'), s:regTask) > -1

  if l:istask == v:false
    return
  endif

  let l:attributeName = s:Trim(input('name:'))

  if len(l:attributeName) == 0
    return
  endif

  let l:attributeValue = input('value:')

  call s:SetAttribute(l:attributeName, l:attributeValue)
endfunc

function! s:CalculateWorkedTime(...)
  let l:dateFormat = a:3
  let l:started = a:1
  let l:currentlyWorked = a:2

  let l:startedAsLocalTime = get(matchlist(l:started, ' / \(\d\+\)'), 1)
  let l:currentlyWorkedAsMinutes = get(matchlist(l:currentlyWorked, '\(\d\+\)h'), 1) * 60 + get(matchlist(l:currentlyWorked, '\(\d\+\)min'), 1)

  let l:totalWorkedMinutes = max([l:currentlyWorkedAsMinutes + float2nr(ceil((localtime() - l:startedAsLocalTime) / 60)), 1])

  let l:totalWorkedHours = l:totalWorkedMinutes / 60
  let l:totalWorkedMinutes = l:totalWorkedMinutes % 60

  let l:formattedTotalWorked = ''
  if l:totalWorkedHours != 0
    let l:formattedTotalWorked = l:totalWorkedHours . 'h'
  endif

  let l:formattedTotalWorked .= l:totalWorkedMinutes . 'min'

  call s:SetAttribute('worked', l:formattedTotalWorked)
endfunc

function! s:AddStartedAttribute(dateFormat)
  return strftime(a:dateFormat) . ' / ' . localtime()
endfunc

" returns a list of all projects a task is associated with. A task is
" associated with its immediate parent project, but also all parent projects
" of the immediate parent project. A project is a parent of another project
" in case it has a smaller indendation and there is no other project with an
" equal indendation in between both.
function! s:GetProjects(lineNumber)
  let l:lineNumber = a:lineNumber
  let l:results = []
  let l:project = s:GetProject(l:lineNumber)

  if (l:project['lineNr'] == 0)
    return l:results
  endif

  let l:projectDepth = strchars(matchlist(l:project['line'], s:regProject)[1])
  let l:parentProjectDepths = [l:projectDepth]
  call add(l:results, s:GetProjectName(l:project['line']))

  while l:lineNumber > 0
    let l:match = matchlist(getline(l:lineNumber), s:regProject)
    if len(l:match) > 0
      let l:currentDepth = strchars(l:match[1]) 
      if l:currentDepth < l:projectDepth 
	let l:parentProjectAtCurrentDepth = filter(l:parentProjectDepths, 'v:val == ' . l:currentDepth)
	if len(l:parentProjectAtCurrentDepth) == 0
	  call add(l:results, s:GetProjectName(l:match[0]))
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
function! s:GetProjectName(projectLine)
  let l:projectLine = a:projectLine
  let l:trimmedProjectLine = s:Trim(l:projectLine)
  return strcharpart(l:trimmedProjectLine, 0, strchars(l:trimmedProjectLine) - 1)
endfunc

function! s:MarkTaskAs(nextState, forceRemoveAttributes)
  let l:cursorPosition = getcurpos()
  let l:nextState = a:nextState
  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regTask) > -1

  if l:isMatch == v:true
    let l:lineNumber = line('.')
    let l:projects = s:GetProjects(l:lineNumber)

    if empty(l:projects)
      return
    endif

    let l:currentState = s:GetTaskState(l:lineNumber)
    if (l:currentState ==# l:nextState)
      let l:nextState = 'none'
    endif

    if has_key(s:taskStates, l:currentState) == v:true
      let l:currentStateOptions = s:taskStates[l:currentState]
      let l:validNextStates = copy(l:currentStateOptions['next'])
      let l:isValidNextState = !empty(filter(l:validNextStates, 'v:val ==# ' . "l:nextState"))
      if (l:isValidNextState == v:true)
	let l:newLineMarker = s:taskStates[l:nextState]['lineMarker']
	let l:newAttributes = s:taskStates[l:nextState]['attributes']

	call s:SetLineMarker(l:newLineMarker)
	let l:arguments = { 'projects': l:projects, 'separator': ' \ ', 'dateFormat': g:TasksDateFormat, 'started': s:GetAttribute(l:lineNumber, 'started')['value'], 'worked': s:GetAttribute(l:lineNumber, 'worked')['value'] }

	for l:attribute in keys(l:newAttributes)
	  let l:attributeConfiguration = l:newAttributes[l:attribute]
	  let l:ToAddLambda = l:attributeConfiguration['add']
	  let l:toAdd = l:ToAddLambda(l:currentState)

	  if l:toAdd == v:false
	    continue
	  endif

	  let l:attributeFunctionArguments = l:attributeConfiguration['arguments']
	  let l:functionArguments = []

	  for l:attributeFunctionArgument in l:attributeFunctionArguments
	    call add(l:functionArguments, l:arguments[l:attributeFunctionArgument])
	  endfor

	  let l:attributeValue = call(l:attributeConfiguration['function'], l:functionArguments)
	  call s:AddAttribute(l:lineNumber, l:attribute, l:attributeValue)
	endfor

	let l:attributesToRemove = keys(l:currentStateOptions['attributes'])

	for l:attribute in l:attributesToRemove
	  let l:ToRemoveLambda = l:currentStateOptions['attributes'][l:attribute]['remove']
	  let l:toRemove = l:ToRemoveLambda(l:nextState, a:forceRemoveAttributes)

	  if l:toRemove == v:true
	    call s:RemoveAttribute(l:lineNumber, l:attribute)
	  endif
	endfor

      endif
    endif
  endif
  call setpos('.', l:cursorPosition)
endfunc

function! s:GetTaskState(lineNumber)
  let l:line = getline('.')
  let l:match = matchlist(l:line, s:regTask)
  let l:state = ''

  if len(l:match) > 0
    let l:taskMarker = l:match[2]
    if has_key(s:markerToTaskState, l:taskMarker)
      let l:state = s:markerToTaskState[l:taskMarker]
    else
      let l:state = 'invalid'
    endif
  endif

  return l:state
endfunc

function! s:TaskBegin()
  call s:MarkTaskAs('inprogress', 0)
endfunc

function! s:TaskComplete()
  call s:MarkTaskAs('done', 0)
endfunc

function! s:TaskCancel()
  call s:MarkTaskAs('cancelled', 0)
endfunc

" Checks whether a specific line has been marked as done or cancelled.
function! s:IsCompleted(line)
  if match(a:line, s:regDone) > -1
    return v:true
  endif

  if match(a:line, s:regCancelled) > -1
    return v:true
  endif

  return v:false
endfunc

function! s:TasksArchive()
  " go over every line. Compile a list of all cancelled or completed items
  " until the end of the file is reached or the archive project is
  " detected, whicheved happens first.
  let l:savedCursorPosition = getcurpos()
  let l:archiveLine = -1
  let l:completedTasks = []
  let l:lineNr = 1
  let l:lastLine = line('$')
  while l:lineNr <= l:lastLine
    let l:line = getline(l:lineNr)
    let l:isCompleted = s:IsCompleted(l:line)
    let l:projectMatch = matchstr(l:line, s:regProject)

    if l:isCompleted == v:true
      call add(l:completedTasks, [l:lineNr, s:Trim(l:line)])
    endif

    if l:projectMatch > -1 && s:Trim(l:line) == 'Archive:'
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
  call setpos('.', l:savedCursorPosition)
endfunc

" currently sorts by priority attributes, but in the future user will be able
" to choose this somehow
function! s:SortTasks()
  set lz

  let l:cursorPosition = getcurpos()
  let l:lineNr = 1
  let l:lastLineNr = line('$')
  let l:groupheaderOrderedTasks = {}
  let l:currentSortingProject = { 'name': '', 'lineNr': 0 }
  let l:lastPriority = 'critical'

  while l:lineNr <= l:lastLineNr
    let l:line = getline(l:lineNr)

    if l:line ==# s:archiveSeparator
      if l:lineNr == l:lastLineNr || s:Trim(getline(l:lineNr + 1)) ==# s:regArchive
	break
      endif
    endif

    let l:project = s:Trim(matchstr(l:line, s:regProject))

    if len(l:project)
      let l:oldSortingProject = copy(l:currentSortingProject)
      let l:currentSortingProject['name'] = l:project
      let l:currentSortingProject['lineNr'] = l:lineNr
      let l:groupheaderOrderedTasks[l:currentSortingProject['name']] = { 'critical': [], 'high': [], 'medium': [], 'low': [] , 'none': [] }

      if l:oldSortingProject['name'] != ''
	call s:PasteTasks(l:oldSortingProject['lineNr'], l:groupheaderOrderedTasks[l:oldSortingProject['name']], l:lastPriority)
      endif
      let l:lastPriority = 'critical'
    else
      let l:isTask = match(l:line, s:regTask) > -1
      if l:isTask == v:true
	let l:priority = s:GetAttribute(l:lineNr, 'priority')['value']
	if l:priority == ''
	  let l:priority = 'none'
	endif
	let l:lastPriority = l:priority
	call add(l:groupheaderOrderedTasks[l:currentSortingProject['name']][l:priority], l:line)
      else
	call add(l:groupheaderOrderedTasks[l:currentSortingProject['name']][l:lastPriority], l:line)
      endif
    endif

    let l:lineNr = l:lineNr + 1
  endwhile

  if l:currentSortingProject['name'] != ''
    call s:PasteTasks(l:currentSortingProject['lineNr'], l:groupheaderOrderedTasks[l:currentSortingProject['name']], l:lastPriority)
  endif

  call setpos('.', l:cursorPosition)
  set nolz
endfunc

function! s:PasteTasks(targetLineNr, groupheaderTasks, lastPriority)
  let l:targetLineNr = a:targetLineNr
  let l:groupheaderTasks = a:groupheaderTasks

  " remove single empty separation line between last task and next header
  if match(l:groupheaderTasks[a:lastPriority], '^\s*$')
    call remove(l:groupheaderTasks[a:lastPriority], -1)
  endif

  let l:noPriorityTasks = reverse(l:groupheaderTasks['none'])
  let l:lowPriorityTasks = reverse(l:groupheaderTasks['low'])
  let l:mediumPriorityTasks = reverse(l:groupheaderTasks['medium'])
  let l:highPriorityTasks = reverse(l:groupheaderTasks['high'])
  let l:criticalPriorityTasks = reverse(l:groupheaderTasks['critical'])
  let l:allTasks = l:noPriorityTasks + l:lowPriorityTasks + l:mediumPriorityTasks + l:highPriorityTasks + l:criticalPriorityTasks

  for l:task in l:allTasks
    call append(l:targetLineNr, l:task)
  endfor

  let l:startRange = l:targetLineNr + len(l:allTasks) + 1
  let l:endRange = l:startRange + len(l:allTasks) - 1
  exec 'silent! ' . l:startRange . ',' . l:endRange . 'delete _'
endfunc

function! s:ToggleTask(removeAttributes)
  let l:line = getline('.')
  let l:isMatch = match(l:line, s:regTask) > -1
  if l:isMatch == v:true
    exec 'silent! s:' . s:regTask . ':\3'
    if a:removeAttributes
      exec 'silent! s:@\w\+\(([^)]*)\)\=::g'
    endif
  else
    call s:NewTask(-1)
    exec 'normal! J'
    stopinsert
  endif
endfunc
