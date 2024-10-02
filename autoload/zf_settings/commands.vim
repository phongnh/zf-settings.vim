function! s:commands_format(line) abort
    let attr = a:line[0:3]
    let [name; line] = split(a:line[4:], ' ')
    let line = zf_settings#trim(join(line, ' '))
    let args = zf_settings#trim(line[0:3])
    " let address = line[5:11]
    " let complete = line[13:22]
    let definition = zf_settings#trim(line[25:])
    let result = [
                \ attr . zf_settings#trim(args) . g:zf_symbols.nbs . name,
                \ zf_settings#trim(definition),
                \ ]
    return result
endfunction

function! s:commands_source() abort
    let items = split(call('execute', ['command']), '\n')[1:]
    return map(zf_settings#align_lists(map(items, 's:commands_format(v:val)')), 'join(v:val, " ")')
endfunction

function! s:commands_sink(line) abort
    let cmd = matchstr(a:line[7:], '\zs\S*\ze')
    call feedkeys(':' . cmd . (a:line[0] == '!' ? '' : ' '), 'n')
endfunction

function! zf_settings#commands#run() abort
    let items = s:commands_source()
    if empty(items)
        return zf_settings#warn('No command items!')
    endif
    call zf#Start(items, funcref('s:commands_sink'), zf_settings#zf_opts('Commands'))
endfunction
