nnoremap <Plug>(-zf-vim-do) :execute g:__zf_command<CR>
nnoremap <Plug>(-zf-/) /
nnoremap <Plug>(-zf-:) :

function! s:history_source(type) abort
    let max = histnr(a:type)
    let fmt = '%' . len(string(max)) . 'd'
    let list = filter(map(range(1, max), 'histget(a:type, -v:val)'), '!empty(v:val)')
    return map(list, 'printf(fmt, v:key) . g:zf_symbols.nbs . v:val')
endfunction

function! s:history_sink(type, line) abort
    let prefix = "\<Plug>(-zf-" . a:type . ')'
    let item = matchstr(a:line, '\s*[0-9]\+' . g:zf_symbols.nbs . '*\zs.*')
    if a:type == ':'
        call histadd(a:type, item)
    endif
    let g:__zf_command = 'normal ' . prefix . item . "\<CR>"
    call feedkeys("\<Plug>(-zf-vim-do)")
endfunction

function! s:history_prompt_sink(type, line) abort
    let prefix = "\<Plug>(-zf-" . a:type . ')'
    let item = matchstr(a:line, '\s*[0-9]\+' . g:zf_symbols.nbs . '*\zs.*')
    call histadd(a:type, item)
    redraw
    call feedkeys(a:type . "\<Up>", 'n')
endfunction

function! zf_settings#history#command(...) abort
    let items = s:history_source(':')
    if empty(items)
        return zf_settings#warn('No command history items!')
    endif
    let sink = get(a:, 1, 0) ? 's:history_sink' : 's:history_prompt_sink'
    call zf#Start(items, funcref(sink, [':']), zf_settings#zf_opts('CommandHistory'))
endfunction

function! zf_settings#history#search(...) abort
    let items = s:history_source('/')
    if empty(items)
        return zf_settings#warn('No search history items!')
    endif
    let sink = get(a:, 1, 0) ? 's:history_sink' : 's:history_prompt_sink'
    call zf#Start(items, funcref(sink, ['/']), zf_settings#zf_opts('SearchHistory'))
endfunction
