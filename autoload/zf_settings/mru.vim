let s:zf_mru_exclude = [
            \ '^/usr/',
            \ '^/opt/',
            \ '^/etc/',
            \ '^/var/',
            \ '^/tmp/',
            \ '^/private/',
            \ '\.git/',
            \ '/\?\.gems/',
            \ '\.vim/plugged/',
            \ '\.fugitiveblame$',
            \ 'COMMIT_EDITMSG$',
            \ 'git-rebase-todo$',
            \ ]

function! s:buflisted() abort
    return filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&filetype") != "qf"')
endfunction

function! s:uniq(list) abort
    let visited = {}
    let ret = []
    for l in a:list
        if !empty(l) && !has_key(visited, l)
            call add(ret, l)
            let visited[l] = 1
        endif
    endfor
    return ret
endfunction

function! s:vim_recent_files() abort
    let recent_files = s:uniq(
                \ map(
                \   filter([expand('%')], 'len(v:val)')
                \   + filter(map(s:buflisted(), 'bufname(v:val)'), 'len(v:val)')
                \   + filter(copy(v:oldfiles), "filereadable(fnamemodify(v:val, ':p'))"),
                \   'fnamemodify(v:val, ":~:.")'
                \ )
                \ )

    for l:pattern in s:zf_mru_exclude
        call filter(recent_files, 'v:val !~ l:pattern')
    endfor

    return recent_files
endfunction

function! s:vim_recent_files_in_cwd() abort
    let l:pattern = '^' . getcwd()
    return filter(s:vim_recent_files(), 'fnamemodify(v:val, ":p") =~ l:pattern')
endfunction

function! s:mru_sink(editcmd, choice) abort
    let fname = fnameescape(a:choice)
    call zf_settings#try_exe(printf('%s %s', a:editcmd, fname))
endfunction

function! zf_settings#mru#run() abort
    let items = s:vim_recent_files()
    if empty(items)
        return zf_settings#warn('No MRU items!')
    endif
    call zf#Start(items, funcref('s:mru_sink', ['edit']), zf_settings#zf_opts('MRU'))
endfunction

function! zf_settings#mru#run_in_cwd() abort
    let items = s:vim_recent_files_in_cwd()
    if empty(items)
        return zf_settings#warn('No MRU items!')
    endif
    call zf#Start(items, funcref('s:mru_sink', ['edit']), zf_settings#zf_opts(printf('MRU [directory: %s]', getcwd())))
endfunction
