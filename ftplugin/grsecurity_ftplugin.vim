" Vim filetype plugin file
" Language:	grsecurity
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 Mar 12
" URL:		
" Copyright:    Copyright (C) 2010 Marcin Szamotulski Permission is hereby
"		granted to use and distribute this code, with or without
" 		modifications, provided that this copyright notice is copied
" 		with it. Like anything else that's free, Automatic TeX Plugin
" 		is provided *as is* and comes with no warranty of any kind,
" 		either expressed or implied. By using this plugin, you agree
" 		that in no event will the copyright holder be liable for any
" 		damages resulting from the use of this software. 
" 		This licence is valid for all files distributed with
" 		grsecurity ftplugin.
"
" ToDo: List_Subjects([role])
" ToDo: Search_fo_Subject doesn't work where subject is not enclosed in { }. 
" Done: variable (list) for lines which we do not want in the output of
" the :Dmesg command.
" ToDo: to write in doc file.
" ToDo: completion should add subjects after the roles
"
" to install this plugin: 
"  	(1) copy this file to $HOME/.vim/ftplugin
"	(2) put in your vimrc file
" 		au BufRead /etc/grsec/policy set filetype=grsecurity
" there is a syntax file for /etc/grsec/policy file written by Jochen Bartl: 
" http://verbosemo.de/~lobo/files/grsecurity.vim
"
" List of Functions:
" SHOW DMESG
"          Show_Dmesg		command :Dmesg		
"          Show_Previous_Logs	command :PL
"          Show_Next_Logs	command :NL
"
" SEARCHING functions/commands/mappings:
"          Search_for_Subject	command :S 	
"          Search_in_Subject	command :SS		
"          Search_in_Role	command :SR
"          Search_for_Object	command :SO
"          Search_i_Flag 	command :Si
"          Search_for_Role 	command :R
"
" MOVING functions/commands/mappings:
"          Top_of_Subject	command :TS
" 				map {
"          Bottom_of_Subject	command :BS
" 				map }
"          Next_Subject		command :NS
" 				map ]
"          Previous_Subject 	command :PS	
"				map [
"          Next_Role		command :NR	
"				map (
"          Previous_Role	command :PR
"				map (
"
" Some function have special arguments which are not explained.

if !exists("g:gradm_learning_log_file")
    let g:gradm_learning_log_file='/etc/grsec/learning.log'
endif
if !exists("g:gradm_output_policy")
    let g:gradm_output_policy='/etc/grsec/policy.add'
endif

if !exists("g:ignore_grsec_logs")
    let g:ignore_grsec_logs='successful change to special role admin\|
		\RBAC system \(re\)\?loaded\|
		\special role admin failure\|
		\special role admin (.*) exited\|
		\unauth of special role admin\|
		\terminal being sniffed by IP:0\.0\.0\.0\|
		\grsec: shutdown auth success for'
" 		\ grsec: mount of'
"
endif

"search for subject anywhere, or in the specified role
function! Search_for_Subject(pattern,...)
    let l:pattern='^\s*subject\s.\{-}' . a:pattern 
    ". '\>\(\s\|$\)'
    if a:0 == 0
	exe '/' . l:pattern
    else
	call Search_in_Role(l:pattern,a:1)
    endif
endfunction

function! Search_i_Flag()
    let l:pattern='^\s*subject\s\+\/\%(\w\|\/\|\.\|-\)*\s\+\<[hvpkldbotrAKCToOa]\{-}i[hvpkldbotrAKCToOa]*\>'
    exe '/' . l:pattern	
" 	call search(l:pattern,'cesw')
endfunction

function! Search_for_Role(what)
    let l:pattern='^\s*\%(role\).\{-}' . a:what . '\>'
    exe '/' . l:pattern
" 	call search(l:pattern,'cesw')	
endfunction

function! Top_of_Subject(...)
    let l:true=getline('.') !~ '^\s*subject\>' 
    let l:line=line('.')
    while l:true && l:line > 1
	let l:line-=1
	let l:true=getline(l:line) !~ '^\s*subject\>'
    endwhile
    if a:0 == 0
	call setpos('.',[bufnr("%"), l:line, 1, 0])
    else
	return l:line
    endif
endfunction

function! Next_Subject() 
    let l:line=line('.')+1
    while getline(l:line) !~ '^\s*subject\>' && l:line <= line('$')
	let l:line+=1
    endwhile
    call setpos('.',[bufnr("%"), l:line, 1, 0])
    exe 'normal zt'
endfunction

function! Next_Role(...) 
    let l:line=line('.')+1
    while getline(l:line) !~ '^\s*role\>' && l:line <= line('$')
	let l:line+=1
    endwhile
    if a:0 == 0
	call setpos('.',[bufnr("%"), l:line, 1, 0])
	exe 'normal zt'
    else
	return l:line
    endif
endfunction

function! Previous_Subject() 
    let l:line=line('.')-1
    while getline(l:line) !~ '^\s*subject\>' && l:line > 1
	let l:line-=1
    endwhile
    call setpos('.',[bufnr("%"), l:line, 1, 0])
    exe 'normal zt'
endfunction

" this finds the top of the current role
function! Previous_Role(...) 
    if line('.') == 1
	return 1
    endif
    let l:line=line('.')-1
    while getline(l:line) !~ '^\s*role\>' && l:line > 1
	let l:line-=1
    endwhile
    if a:0 == 0
	call setpos('.',[bufnr("%"), l:line, 1, 0])
	exe 'normal zt'
    else
	return l:line
    endif
endfunction

function! Bottom_of_Subject(...)
    let l:true=getline('.') !~ '^\s*}\s*$' 
    let l:line=line('.')
    while l:true && l:line < line('$')
	let l:line+=1
	let l:true=getline(l:line) !~ '^\s*}\s*$'
    endwhile
    if a:0 == 0
	call setpos('.',[bufnr("%"), l:line, 1, 0])
    else
	return l:line
    endif
endfunction

" Search in the current subject or in: 
" a:1 = subject
" a:2 = role
function! Search_in_Subject(pattern,...)
    let l:pos=getpos('.')

    if a:0 >= 2
	"if we are not in the role a:2
	if Echo_Role_Subject(1)[0] != a:2
	    call Search_for_Subject(a:1,a:2)

	"if we are in the role a:2, but not in the subject wich mathes a:1
	elseif len(Echo_Role_Subject(1)) == 2 && Echo_Role_Subject(1)[1] !~ a:1
	    call Search_for_Subject(a:1,a:2)
	endif
    endif

    let l:bottom_line=Bottom_of_Subject(1)
    let l:return=search(a:pattern,'sW',l:bottom_line)

    " if we hit bottom continue at top of the subject
    if l:return == 0
	keepjumps call Top_of_Subject()

	" echo warning message if hit bottom 
	echoh WarningMsg
	echomsg "Search hit BOTTOM of the subject, continuing at TOP of the subject"
	echoh None
	let l:return=search(a:pattern,'sW',l:bottom_line)
	if l:return == 0
	    call setpos('.',l:pos)
	endif
    endif
endfunction

" search for pattern in role (default in the current role)
function! Search_in_Role(pattern,...)

    " get the current position
    let l:pos=getpos('.')

    " go to the role a:1
    if a:0 != 0 && Echo_Role_Subject(1)[0] != a:1
	keepjumps call Search_for_Role(a:1)
    endif

    let l:bottom_line=Next_Role(1)-1
    let l:return=search(a:pattern,'sW',l:bottom_line)
    if l:return == 0

	" if we hit bottom continue at top of the role
	if getline('.') !~ '^\s*role\>'
	    keepjumps call Previous_Role()

	    " echo warning message if hit bottom 
	    echoh WarningMsg
	    echomsg "Search hit BOTTOM of the role, continuing at TOP of the role"
	    echoh None
	else
	    " set the begining position if nothing has been found
	    " and issue a warning message
	    call setpos('.',l:pos)
	    if a:0 == 0
		let l:msg=""
	    else
		let l:msg=" in the role: " . a:1
	    endif
	    echohl WarningMsg
	    echomsg "Pattern: '" . a:pattern . "' not found" . l:msg
	    echohl None
	    return 0
	endif
	let l:return=search(a:pattern,'sW',l:bottom_line)
	if l:return == 0 

	    " set the begining position if nothing has been found
	    " and issue a warning message
	    call setpos('.',l:pos)
	    if a:0 == 0
		let l:msg=""
	    else
		let l:msg=" in the role " . a:1
	    endif
	    echohl WarningMsg
	    echomsg "Pattern " . a:pattern . " not found" . l:msg
	    echohl None
	endif
    endif
endfunction

function! Role_Compl(A,P,L,...)

    let l:roles=[]
    let l:roles_lines=getbufline(bufname('%'),1,'$')

    " filter out not matching lines
    call filter(l:roles_lines, 'v:val =~ "\\s*role\\s"')

    for l:role in l:roles_lines
	call add(l:roles,substitute(substitute(l:role,'#.*$','',''),'^\s*role\s\+\(\%(\w\|_\|\.\|-\)*\)\%(\s\+[ANsugGTlP]*\)\?\s*$','\1',''))
    endfor

    " we are not sorting the results as probably roles appears in a logical
    " order
    
    let l:returnlist=[]
    if a:0 == 0
	for l:role in l:roles
	    if l:role =~ '^' . a:A 
		call add(l:returnlist,l:role)
	    endif
	endfor
	return l:returnlist
    else
	echo join(l:roles,"\n")
    endif
endfunction

function! Role_Subject_Compl(A,P,L)
    let l:roles=Role_Compl(a:A,a:P,a:L)

    let l:subjects=[]
    let l:subject_lines=readfile(fnamemodify(bufname('%'),':p'))

    " filter out not matching lines
    call filter(l:subject_lines, 'v:val =~ "\\s*subject\\s"')

    for l:subject in l:subject_lines
	call add(l:subjects,fnamemodify(substitute(substitute(l:subject,'#.*$','',''),'^\s*subject\s\+\(\S\+\)\s\+.*','\1',''),":t"))
    endfor
    "
    " we are not sorting the results as probably roles appears in a logical
    " order
    
    let l:roles_and_subjects=l:roles+l:subjects

    let l:returnlist=[]
    for l:subject_or_role in l:roles_and_subjects
	if l:subject_or_role =~ '^' . a:A 
	    call add(l:returnlist,l:subject_or_role)
	endif
    endfor
    return l:returnlist
endfunction

function! Echo_Role_Subject(...)
" 	let l:pos=getpos('.')
    let l:sline=Top_of_Subject(1)
    if getline('.') =~ '^\s*role\>' 
	let l:rline=line('.')
    else
	let l:rline=Previous_Role(1)
    endif
    let l:subject=substitute(substitute(getline(l:sline),'#.*$','',''),'^\s*subject\s\+\(\/\%(\w\|\/\|\.\|-\|_\)*\)\s\+[hvpkldbotrAKCToOa]*\s*{\?\s*$','\1','')
    let l:role=substitute(substitute(getline(l:rline),'#.*$','',''),'^\s*role\s\+\(\%(\w\|_\|\.\|-\)*\)\%(\s\+[ANsugGTlP]*\)\?\s*$','\1','')
" 	echo l:role . "  " . l:subject 
	
    if l:rline <= l:sline && a:0 == 0
	return l:role . "  " . l:subject 
    elseif a:0 == 0
	return l:role
    endif
    if l:rline <= l:sline && a:0 != 0
	return [l:role, l:subject]
    elseif a:0 !=0
	return [l:role]
    endif
endfunction

" search for object [flag]
function! Search_for_Object(object,...)
    if a:0==0
	call search('^\s*' . a:object)
    else

	if a:0 >= 1
	    " flags which must appear
	    if a:1 != 'any' || a:1 == 'all'
		let l:a_flags=split(a:1,'\zs')
		let l:any_flag=0
	    else
" 		let l:a_flags=[]
		let l:any_flag=1
	    endif
	    let l:n_flags=[]
	endif
	if a:0 >= 2
	    " flags which must not appear
	    let l:n_flags=split(a:2,'\zs')
	endif
" 	echomsg "DEBUG " string(l:a_flags) . " " . string(l:n_flags) . " any:" l:any_flag

	let l:use_flag_list=[]
	let l:use_flag_word=join(l:use_flag_list)
	let l:true=1
	let l:cpos=getpos(".")
	let l:hit_bottom=0

	while l:true
	    
	    keepjumps let l:s=search('^\s*' . a:object,'W')
	    while getline('.') =~ 'connect\|bind\|subject\|role\|user_transition\|group_transition\|\%(+\|-\)\s*CAP_'
		keepjumps let l:s=search('^\s*' . a:object,'')
	    endwhile

	    if l:s == 0 && l:hit_bottom != 0
		keepjumps call setpos('.',l:cpos)

		echoh WarningMsg
		echomsg "Object not found"
		echoh None

		break
	    endif
	    if l:s == 0 && l:hit_bottom == 0 
		let l:bpos=copy(l:cpos)
		let l:bpos[1]=1
		keepjumps call setpos('.',l:bpos)

		echoh WarningMsg
		echomsg "Search hit BOTTOM, continuing at TOP"
		echoh None

		let l:hit_bottom=1
	    endif

	    let l:line=getline(".")
	    let l:flags_in_line=split(substitute(substitute(substitute(l:line,'#.*$','',''),'^\s\%(\w\|\/\|\.\|-\|?\|*\|\~\|:\|_\)*\s*','',''),'\s\+\%(#.*\|$\)','',''),'\zs')
" 	    echomsg "DEBUG LINE " . line(".") . " " . l:line
" 	    echomsg "DEBUG flags_in_line=" . string(l:flags_in_line)

	    let l:not_matched=0
	    if l:any_flag == 0
	    for l:f in l:a_flags 
		if index(l:flags_in_line,l:f) == -1
		    let l:not_matched=1
		endif
	    endfor
	    endif
" 	    echomsg "DEBUG A " . l:not_matched
"
	    for l:f in l:n_flags
		if index(l:flags_in_line,l:f) != -1
		    let l:not_matched=1
		endif
	    endfor
" 	    echomsg "DEBUG B " . l:not_matched

	    if l:not_matched == 0
		let l:true=0
		" this is to add position to the jump list
		call setpos('.',getpos('.'))
	    endif

	endwhile
    endif
endfunction


" show all RBAC log messages
setl errorformat=%m

function! Show_Dmesg()

    "first test if we can use dmesg
    let l:c="dmesg > /dev/null;echo $?" 
    let l:test=system(l:c)
    if l:test =~ 1
	echoerr "You are not privillaged to use dmesg"
	return 0
    endif

    if !exists("s:show_dmesg_number")
	let s:show_dmesg_number=1
    else
	let s:show_dmesg_number+=1
    endif
    let s:log_number=s:show_dmesg_number

    " dictinary to keep names of temporary files
    if !exists("b:logs_dict")
	let b:logs_dict={}
    endif

    let l:name=tempname()

    " find the last log when RBAC was (re)loaded
    call extend(b:logs_dict, { s:show_dmesg_number : l:name }, 'force')

    let l:comm="dmesg | 
		\ grep '^grsec' | 
		\ tac |
		\ egrep -m1 -n 'RBAC system loaded'\\|'RBAC system reloaded' | 
		\ awk '{print $1}' | 
		\ sed 's/:grsec://g'"	
    let b:comm=l:comm

    " read only the current logs
    let l:linenr=system(l:comm)
    let l:linenr=substitute(l:linenr,'\D','','g')
    let l:com="dmesg | grep '^grsec' | tail -" . l:linenr . " > " . l:name 
    call system(l:com)

    " remove double lines from log file
    let l:log=readfile(l:name)

    let l:nlog=[]
    for l:line in l:log
	if index(l:nlog,l:line) == -1 && l:line !~ "grsec: more alerts, logging disabled" && l:line !~ g:ignore_grsec_logs
	    call add(l:nlog,l:line)
	endif
    endfor
    let b:nlog=l:nlog
    call writefile(l:nlog,l:name)
	
    " set the errorfile and list errors
    let &l:errorfile=l:name
    cg
    if !empty(getqflist())
	cl
    else
	echomsg "No grsec log messages."
    endif

    if s:show_dmesg_number > 1 && readfile(l:name) == readfile(b:logs_dict[s:show_dmesg_number-1])
	call delete(b:logs_dict[s:show_dmesg_number])
	call remove(b:logs_dict,s:show_dmesg_number)
	let s:show_dmesg_number-=1
	let s:log_number-=1
    endif
endfunction
map <buffer> \e :echo Echo_Role_Subject()<CR>

function! Show_Previous_Logs()

    if !exists("s:show_dmesg_number")
	return
    endif

    if !exists("s:log_number")
	let s:log_number=s:show_dmesg_number
    endif
	let b:s=s:show_dmesg_number
	let b:l=s:log_number

    if s:log_number > 1 && s:show_dmesg_number > 1
	let s:log_number-=1
	let &l:errorfile=b:logs_dict[s:log_number]
	cg
	cl
    else
	echohl WarningMsg
	echo "No PREVIOUS grsec log messages"
	echohl None
    endif
endfunction

function! Show_Next_Logs()

    if !exists("s:show_dmesg_number")
	return
    endif

    if !exists("s:log_number")
	let s:log_number=s:show_dmesg_number
    endif

    if s:log_number < s:show_dmesg_number
	let s:log_number+=1
	let &l:errorfile=b:logs_dict[s:log_number]
	cg
	cl
    else
	echohl WarningMsg
	echo "No NEXT grsec log messages"
	echohl None
    endif
endfunction

" set the log number
function! Log_Nr(nr)
    let l:nr=a:nr-1
    if get(keys(b:logs_dict),l:nr,'-1') != -1 
	let s:log_number=a:nr
	let &l:errorfile=b:logs_dict[a:nr]
    else
	echo "no such log"
    endif
    set ef?
endfunction
function! Log_Compl(A,P,L)
    return keys(b:logs_dict)
endfunction

function! Remove_Logs()
    if !exists("b:logs_dict")
	return 0
    endif

    " remove temporary files
    for l:tempfile in values(b:logs_dict)
	call delete(l:tempfile)
    endfor

    " clear the b:logs_dict variable
    let b:logs_dict={}
    unlet s:show_dmesg_number
endfunction

function! Save_Log(path)
    let l:log=readfile(b:logs_dict[s:log_number])
    call writefile(l:log,a:path)
endfunction

function! s:index(list,pat)
    let l:len = len(a:list)
    let l:i = 0
    while l:i <= l:len-1
	if a:list[l:i] =~ a:pat
	    break
	endif
	let l:i+=1
    endwhile

    return l:i
endfunction

function! s:filter(list,pat)

    let l:len = len(a:list)
    let l:i = 0

    let l:list=[]
    while l:i <= l:len-1
	if a:list[l:i] =~ a:pat
	    call add(l:list,a:list[l:i])
	endif
	let l:i+=1
    endwhile

    return l:list
endfunction

" function! Remove(list,beg,end)
"     let l:len=len(a:list)

function! ListSubjects(role)
    let l:policy=getbufline(bufname("%"),1,'$')
    let l:policy=s:filter(l:policy, '^\s*\%(role\|subject\)\s.*')
    let b:po=deepcopy(l:policy)
    let l:beg=s:index(l:policy,'^\s*role\s\+' . a:role)
    let l:policy=remove(l:policy,l:beg+1,-1)
    let l:end=s:index(l:policy,'^\s*role\s')
    let l:policy=remove(l:policy,0,l:end-1)
    call sort(l:policy)

    exe	"40vsplit\\ +setl\\ wiw=15\\ buftype=nofile\\ nowrap"
    setl ft=grsecurity
    map <buffer> q :q!<CR>
    let l:line=1
    for l:s in l:policy
	call setline(l:line,substitute(substitute(l:s,'\s*#.*$','',''),'{\s*','',''))
	let l:line+=1
    endfor
endfunction

function! Reload()
    if !executable('gradm')
	echohl WarnningMsg
	echomsg "You are not previllage to use gradm"
	echohl None
	return
    endif
    !gradm -R
    !gradm -a admin
endfunction

function! Admin()
    if !executable('gradm')
	echohl WarnningMsg
	echomsg "You are not previllage to use gradm"
	echohl None
	return
    endif
    !gradm -a admin
endfunction

" function! EnableLearning()
"     if !executable('gradm')
" 	echohl WarnningMsg
" 	echomsg "You are not previllage to use gradm"
" 	echohl None
" 	return
"     endif
"     !gradm -S | grep enabled
"     if v:shell_error == 0
" 	    " if gradm is on	
" 	!gradm -D
"     endif
"     call system("gradm -E -L " . g:gradm_learning_log_file)
" endfunction

function! Learn()
    call system("gradm -L " . g:gradm_learning_log_file " . " -O " . g:gradm_output_policy")
    exe "vsplit " . g:gradm_output_policy
endfunction

let &l:statusline='%<%f %(%h%m%r %)%=%{Echo_Role_Subject()}    %-15.15(%l,%c%V%)%P'

command! -buffer -nargs=+ -complete=customlist,Role_Subject_Compl S 	:call Search_for_Subject(<f-args>)
command! -buffer -complete=customlist,Role_Compl -nargs=+ R 	 	:call Search_for_Role(<f-args>)
command! -buffer -nargs=+ -complete=customlist,Role_Subject_Compl SS 	:call Search_in_Subject(<f-args>)
command! -buffer -complete=customlist,Role_Subject_Compl -nargs=+ SR 	:call Search_in_Role(<f-args>)
command! -buffer -nargs=+ SO 	:call Search_for_Object(<f-args>)
command! -buffer Si 		:call Search_i_Flag()
command! -buffer NS 		:call Next_Subject()
command! -buffer NL 		:call Show_Next_Logs()
command! -buffer PL 		:call Show_Previous_Logs()
command! -buffer RemoveLogs	:call Remove_Logs()
map <buffer> ] :NS<CR>
command! -buffer PS 		:call Previous_Subject()
map <buffer> [ :PS<CR>
command! -buffer NR 		:call Next_Role()
map <buffer> ) :NR<CR>
command! -buffer PR 		:call Previous_Role()
map <buffer> ( :PR<CR>
command! -buffer TS 		:call Top_of_Subject()
map <buffer> { :TS<CR>
command! -buffer BS 		:call Bottom_of_Subject()
map <buffer> } :BS<CR>
command! -buffer Dmesg 		:call Show_Dmesg()
command! -buffer -complete=customlist,Log_Compl -nargs=1 LogNr	:call Log_Nr(<f-args>)
command! -buffer ListRoles	:call Role_Compl('','','',1)
command! -buffer -nargs=1 -complete=file SaveLog	:call Save_Log(<f-args>)
command! -buffer Reload		:call Reload()	
command! -buffer Admin		:call Admin()
command! -buffer Enable		:!gradm -E 
" command! -buffer EnableLearning	:call EnableLearning()
command! -buffer Learn		:call Learn()
" command! -buffer -nargs=1 EnableLog :call system("gradm -E -L " . <args>)
command! -buffer Disable	:!gradm -D
command! -buffer -nargs=1 -complete=customlist,Role_Compl ListSubjects		:call ListSubjects(<f-args>)
