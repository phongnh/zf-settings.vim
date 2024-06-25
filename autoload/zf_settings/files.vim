function! s:open_file_sink(dir, vim_cmd, choice) abort
    let fpath = fnamemodify(a:dir, ':p:s?/$??') . '/' . a:choice
    let fpath = fpath->resolve()->fnamemodify(':.')->fnameescape()
    call zf_settings#TryExe(printf('%s %s', a:vim_cmd, fpath))
endfunction

function! s:opts(opts) abort
    let l:opts = extend({ 'dir': getcwd(), 'findcmd': g:zf_find_command, 'editcmd': 'edit', 'mods': '' }, a:opts)
    let l:opts.dir = empty(l:opts.dir) ? getcwd() : l:opts.dir
    let l:opts.path = l:opts.dir->expand(v:true)->fnamemodify(':~')->simplify()
    let l:opts.filecmd = printf('cd %s ; %s', l:opts.path->expand(v:true)->shellescape(), l:opts.findcmd)
    let l:opts.opencmd = empty(l:opts.mods) ? l:opts.editcmd : (l:opts.mods . ' ' . l:opts.editcmd)
    let l:opts.stl = printf(':%s [directory: %s]', l:opts.opencmd, l:opts.path)
    return l:opts
endfunction

function! zf_settings#files#run(...) abort
    let l:opts = s:opts(get(a:, 1, {}))
    call zf#Start(l:opts.filecmd, funcref('s:open_file_sink', [l:opts.path, l:opts.opencmd]), zf_settings#ZfOpts(l:opts.stl))
endfunction

function! zf_settings#files#all(...) abort
    let l:opts = extend(get(a:, 1, {}), { 'findcmd': g:zf_find_all_command })
    call zf_settings#files#run(l:opts)
endfunction

function! zf_settings#files#git(...) abort
    let l:opts = extend(get(a:, 1, {}), { 'findcmd': 'git ls-files . --cached --others --exclude-standard' })
    call zf_settings#files#run(l:opts)
endfunction
