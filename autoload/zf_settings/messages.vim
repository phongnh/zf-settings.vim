function! s:messages_sink(e) abort
    let @" = a:e
    echohl ModeMsg
    echo 'Yanked!'
    echohl None
endfunction

function! s:messages_source() abort
    return split(call('execute', ['messages']), '\n')
endfunction

function! zf_settings#messages#run() abort
    let items = s:messages_source()
    if empty(items)
        return zf_settings#warn('No message items!')
    endif
    call zf#Start(items, funcref('s:messages_sink'), zf_settings#zf_opts('Messages'))
endfunction
