if globpath(&rtp, 'plugin/zf.vim') == ''
    echohl WarningMsg | echomsg 'vim-zf is not found.' | echohl none
    finish
endif

if get(g:, 'loaded_zf_settings_vim', 0)
    finish
endif

let g:zf_symbols = {
            \ 'nbs': nr2char(0xa0),
            \ 'tab': repeat(nr2char(0xa0), 4),
            \ }

let g:zf = {
            \ 'histadd': v:false,
            \ 'term_highlight': 'Terminal',
            \ 'popup': {
            \   'minwidth': 80,
            \   'highlight': 'NormalFloat',
            \   'borderhighlight': ['NormalFloat'],
            \ },
            \ }

if exists('g:zf_exe') && executable(g:zf_exe)
    let g:zf.exe = g:zf_exe
endif

let g:zf_popup_style = get(g:, 'zf_popup_style', 'default')

if g:zf_popup_style ==# 'none'
    let g:zf.popup.borderchars = [' ']
elseif g:zf_popup_style ==# 'bold'
    let g:zf.popup.borderchars = ['━', '┃', '━', '┃', '┏', '┓', '┛', '┗']
elseif g:zf_popup_style ==# 'single'
    let g:zf.popup.borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']
elseif g:zf_popup_style ==# 'double'
    let g:zf.popup.borderchars = ['═', '║', '═', '║', '╔', '╗', '╝', '╚']
else
    let g:zf.popup.borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
endif

" Check if Popup/Floating Win is available
if (has('nvim') && exists('*nvim_open_win') && has('nvim-0.4.2')) ||
            \ (exists('*popup_create') && has('patch-8.2.191'))
    let g:zf_popup = v:true
else
    let g:zf_popup = v:false
endif

let g:zf_find_tool          = get(g:, 'zf_find_tool', 'fd')
let g:zf_find_no_ignore_vcs = get(g:, 'zf_find_no_ignore_vcs', 0)
let g:zf_follow_links       = get(g:, 'zf_follow_links', 1)
let g:zf_grep_no_ignore_vcs = get(g:, 'zf_grep_no_ignore_vcs', 0)

let g:zf_ctags_bin    = get(g:, 'zf_ctags_bin', 'ctags')
let g:zf_ctags_ignore = expand(get(g:, 'zf_ctags_ignore', ''))
let g:zf_tags_command = g:zf_ctags_bin . (filereadable(g:zf_ctags_ignore) ? ' --exclude=@' . g:zf_ctags_ignore : '') . ' -R'

function! s:BuildFindCommand() abort
    let l:find_commands = {
                \ 'fd': 'fd --type file --color never --hidden',
                \ 'rg': 'rg --files --color never --ignore-dot --ignore-parent --hidden',
                \ }
    let g:zf_find_command = l:find_commands[g:zf_find_tool ==# 'rg' ? 'rg' : 'fd']
    let g:zf_find_command .= (g:zf_follow_links ? ' --follow' : '')
    let g:zf_find_command .= (g:zf_find_no_ignore_vcs ? ' --no-ignore-vcs' : '')
    call extend(g:zf, { 'findcmd': g:zf_find_command })
endfunction

function! s:BuildFindAllCommand() abort
    let l:find_all_commands = {
                \ 'fd': 'fd --type file --color never --no-ignore --exclude .git --hidden --follow',
                \ 'rg': 'rg --files --color never --no-ignore --exclude .git --hidden --follow',
                \ }
    let g:zf_find_all_command = l:find_all_commands[g:zf_find_tool ==# 'rg' : 'fd']
    call extend(g:zf, { 'findcmd': g:zf_find_all_command })
endfunction

function! s:BuildGrepCommand() abort
    let g:zf_grep_command = 'rg --color=never -H --no-heading --line-number --smart-case --hidden'
    let g:zf_grep_command .= g:zf_follow_links ? ' --follow' : ''
    let g:zf_grep_command .= g:zf_grep_no_ignore_vcs ? ' --no-ignore-vcs' : ''
    call extend(g:zf, { 'grepcmd': g:zf_grep_command, 'grepformat': '%f:%l:%m' })
endfunction

function! s:SetupZfSettings() abort
    call s:BuildFindAllCommand()
    call s:BuildFindCommand()
    call s:BuildGrepCommand()
    call s:UpdatePopupSettings()
endfunction

function! s:UpdatePopupSettings() abort
    let l:popupwin = g:zf_popup && &columns >= 80 ? v:true : v:false
    call extend(g:zf, {
                \ 'height': l:popupwin ? float2nr(&lines * 0.85 / 2) : 12,
                \ 'popupwin': l:popupwin,
                \ })
    call extend(g:zf.popup, {
                \ 'minwidth': min([float2nr(&columns * 0.75), 150]),
                \ 'minheight': float2nr(&lines * 0.85),
                \ })
endfunction

augroup zfSettings
    autocmd!
    autocmd VimEnter * call <SID>SetupZfSettings()
    autocmd VimResized * call <SID>UpdatePopupSettings()
augroup END

function! s:ToggleZfFollowLinks() abort
    if g:zf_follow_links == 0
        let g:zf_follow_links = 1
        echo 'zf follows symlinks!'
    else
        let g:zf_follow_links = 0
        echo 'zf does not follow symlinks!'
    endif
    call s:BuildFindCommand()
    call s:BuildGrepCommand()
endfunction

command! ToggleZfFollowLinks call <SID>ToggleZfFollowLinks()

command! -nargs=? -complete=dir ZfFiles         call zf_settings#files#run({ 'dir': empty(<q-args>) ? getcwd() : <q-args> })
command! -nargs=? -complete=dir ZfAllFiles      call zf_settings#files#all({ 'dir': empty(<q-args>) ? getcwd() : <q-args> })
command! -nargs=? -complete=dir ZfGitFiles      call zf_settings#files#git({ 'dir': empty(<q-args>) ? getcwd() : <q-args> })
command! -nargs=? -complete=dir ZfFilesSplit    call zf_settings#files#run({ 'dir': empty(<q-args>) ? getcwd() : <q-args>, 'editcmd': 'split', 'mods': <q-mods> })
command! -nargs=? -complete=dir ZfAllFilesSplit call zf_settings#files#all({ 'dir': empty(<q-args>) ? getcwd() : <q-args>, 'editcmd': 'split', 'mods': <q-mods> })
command! -nargs=? -complete=dir ZfGitFilesSplit call zf_settings#files#git({ 'dir': empty(<q-args>) ? getcwd() : <q-args>, 'editcmd': 'split', 'mods': <q-mods> })

command!       ZfMru            call zf_settings#mru#run()
command!       ZfMruCwd         call zf_settings#mru#run_in_cwd()
command!       ZfMruInCwd       call zf_settings#mru#run_in_cwd()
command!       ZfBLines         call zf_settings#blines#run()
command!       ZfBTags          call zf_settings#btags#run()
command!       ZfBOutline       call zf_settings#boutline#run()
command!       ZfQuickfix       call zf_settings#quickfix#quickfix()
command!       ZfLocationList   call zf_settings#quickfix#loclist()
command!       ZfCommands       call zf_settings#commands#run()
command! -bang ZfCommandHistory call zf_settings#history#command(<bang>)
command! -bang ZfSearchHistory  call zf_settings#history#search(<bang>)
command!       ZfRegisters      call zf_settings#registers#run()
command!       ZfMessages       call zf_settings#messages#run()
command!       ZfJumps          call zf_settings#jumps#run()

let g:loaded_zf_settings_vim = 1
