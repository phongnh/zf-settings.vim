" columns: tag | filename | linenr | kind | ref
function! s:boutline_format(line) abort
    let columns = split(a:line, "\t")
    let format = '%' . len(string(line('$'))) . 's'
    let linenr = columns[2][:len(columns[2])-3]
    let line = zf_settings#Trim(getline(linenr))
    return join([printf(format, linenr), line], g:zf_symbols.sep)
endfunction

function! s:boutline_source(tag_cmds) abort
    if !filereadable(expand('%'))
        throw 'Save the file first'
    endif

    let lines = []

    for cmd in a:tag_cmds
        let lines = split(system(cmd), "\n")
        if !v:shell_error && len(lines)
            break
        endif
    endfor

    if v:shell_error
        throw get(lines, 0, 'Failed to extract tags')
    elseif empty(lines)
        throw 'No tags found'
    endif

    return map(lines, 's:boutline_format(v:val)')
endfunction

function! s:boutline_sink(path, editcmd, line) abort
    let linenr = zf_settings#Trim(split(a:line, g:zf_symbols.sep)[0])
    execute printf("%s +%s %s", a:editcmd, linenr, a:path)
endfunction

function! s:boutline_tag_commands() abort
    let language = get({ 'cpp': 'c++' }, &filetype, &filetype)
    let filename = expand('%:S')
    let null = has('win32') || has('win64') ? 'nul' : '/dev/null'
    let ctags_options = '-f - --sort=no --excmd=number' . get({ 'ruby': ' --kinds-ruby=-r' }, language, '')
    return [
                \ printf('%s %s --language-force=%s %s 2> %s', g:zf_ctags_bin, ctags_options, language, filename, null),
                \ printf('%s %s %s 2> %s', g:zf_ctags_bin, ctags_options, filename, null),
                \ ]
endfunction

function! zf_settings#boutline#run() abort
    try
        let tag_cmds = s:boutline_tag_commands()
        call zf#Start(s:boutline_source(tag_cmds), funcref('s:boutline_sink', [expand('%:p'), 'silent edit']), zf_settings#ZfOpts('BOutline: ' . expand('%')))
    catch
        call zf_settings#Warn(v:exception)
    endtry
endfunction
