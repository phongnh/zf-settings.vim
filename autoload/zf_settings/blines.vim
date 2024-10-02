function! s:blines_sink(line) abort
  normal! m'
  execute split(a:line, g:zf_symbols.tab)[0]
  normal! ^zvzz
endfunction

function! s:blines_source() abort
    let linefmt = '%' . len(string(line('$'))) . 'd'
    let format = linefmt . g:zf_symbols.tab . '%s'
    return map(getline(1, '$'), 'printf(format, v:key + 1, v:val)')
endfunction

function! zf_settings#blines#run() abort
    let items = s:blines_source()
    if empty(items)
        return zf_settings#warn('No lines!')
    endif
    call zf#Start(items, funcref('s:blines_sink'), zf_settings#zf_opts('BufLines: ' . expand('%')))
endfunction
