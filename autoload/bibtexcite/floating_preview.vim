" Copyright (c) 2016-2020, w0rp <devw0rp@gmail.com>
" All rights reserved.

" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:

" 1. Redistributions of source code must retain the above copyright notice, this
"    list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.

" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
" ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
" WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
" DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
" ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
" (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
" LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
" ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
" (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
" SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
"
" Author: Jan-Grimo Sobez <jan-grimo.sobez@phys.chem.ethz.ch>
" Author: Kevin Clark <kevin.clark@gmail.com>
" Author: D. Ben Knoble <ben.knoble+github@gmail.com>
" Description: Floating preview window for showing whatever information in.

" Precondition: exists('*nvim_open_win') || has('popupwin')

function! bibtexcite#floating_preview#Show(lines, ...) abort
    if !exists('*nvim_open_win') && !has('popupwin')
        execute 'echom ''Floating windows not supported in this vim instance.'''

        return
    endif

    let l:options = get(a:000, 0, {})

    if has('nvim')
        call s:NvimShow(a:lines, l:options)
    else
        call s:VimShow(a:lines, l:options)
    endif
endfunction

function! s:NvimShow(lines, options) abort
    " Remove the close autocmd so it doesn't happen mid update
    augroup bibtexcite_floating_preview_window
        autocmd!
    augroup END

    " Only create a new window if we need it
    if !exists('w:preview') || index(nvim_list_wins(), w:preview['id']) is# -1
        call s:NvimCreate(a:options)
    else
        call nvim_buf_set_option(w:preview['buffer'], 'modifiable', v:true)
    endif

    " Execute commands in window context
    let l:parent_window = nvim_get_current_win()

    call nvim_set_current_win(w:preview['id'])

    for l:command in get(a:options, 'commands', [])
        call execute(l:command)
    endfor

    call nvim_set_current_win(l:parent_window)

    " Return to parent context on move
    augroup bibtexcite_floating_preview_window
        autocmd!

        if g:bibtexcite_close_preview_on_insert
            autocmd CursorMoved,TabLeave,WinLeave,InsertEnter <buffer> ++once call s:NvimClose()
        else
            autocmd CursorMoved,TabLeave,WinLeave <buffer> ++once call s:NvimClose()
        endif
    augroup END

    let [l:lines, l:width, l:height] = s:NvimPrepareWindowContent(a:lines)

    call nvim_win_set_width(w:preview['id'], l:width)
    call nvim_win_set_height(w:preview['id'], l:height)
    call nvim_buf_set_lines(w:preview['buffer'], 0, -1, v:false, l:lines)
    call nvim_buf_set_option(w:preview['buffer'], 'modified', v:false)
    call nvim_buf_set_option(w:preview['buffer'], 'modifiable', v:false)
endfunction

function! s:VimShow(lines, options) abort
    if g:bibtexcite_close_preview_on_insert
        " Remove the close autocmd so it doesn't happen mid update
        silent! autocmd! bibtexcite_floating_preview_window
    endif

    " Only create a new window if we need it
    if !exists('w:preview') || index(popup_list(), w:preview['id']) is# -1
        call s:VimCreate(a:options)
    endif

    " Execute commands in window context
    for l:command in get(a:options, 'commands', [])
        call win_execute(w:preview['id'], l:command)
    endfor

    call popup_settext(w:preview['id'], a:lines)

    if g:bibtexcite_close_preview_on_insert
        augroup bibtexcite_floating_preview_window
            autocmd!
            autocmd InsertEnter * ++once call s:VimClose()
        augroup END
    endif
endfunction

function! s:NvimPrepareWindowContent(lines) abort
    let l:max_height = 40

    let l:width = max(map(copy(a:lines), 'strdisplaywidth(v:val)'))
    let l:height = min([len(a:lines), l:max_height])

    if empty(g:bibtexcite_floating_window_border)
        return [a:lines, l:width, l:height]
    endif

    " Add the size of borders
    let l:width += 2
    let l:height += 2

    let l:hor          = g:bibtexcite_floating_window_border[0]
    let l:top          = g:bibtexcite_floating_window_border[1]
    let l:top_left     = g:bibtexcite_floating_window_border[2]
    let l:top_right    = g:bibtexcite_floating_window_border[3]
    let l:bottom_right = g:bibtexcite_floating_window_border[4]
    let l:bottom_left  = g:bibtexcite_floating_window_border[5]

    let l:lines = [l:top_left . repeat(l:top, l:width - 2) . l:top_right]

    for l:line in a:lines
        let l:line_width = strchars(l:line)
        let l:lines = add(l:lines, l:hor . l:line . repeat(' ', l:width - l:line_width - 2). l:hor)
    endfor

    " Truncate the lines
    if len(l:lines) > l:max_height + 1
        let l:lines = l:lines[0:l:max_height]
    endif

    let l:lines = add(l:lines, l:bottom_left . repeat(l:top, l:width - 2) . l:bottom_right)

    return [l:lines, l:width, l:height]
endfunction

function! s:NvimCreate(options) abort
    let l:buffer = nvim_create_buf(v:false, v:false)
    let l:winid = nvim_open_win(l:buffer, v:false, {
    \ 'relative': 'cursor',
    \ 'row': 1,
    \ 'col': 0,
    \ 'width': 42,
    \ 'height': 4,
    \ 'style': 'minimal'
    \ })
    call nvim_buf_set_option(l:buffer, 'buftype', 'acwrite')
    call nvim_buf_set_option(l:buffer, 'bufhidden', 'delete')
    call nvim_buf_set_option(l:buffer, 'swapfile', v:false)
    call nvim_buf_set_option(l:buffer, 'filetype', get(a:options, 'filetype', 'bibtexcite-preview'))

    let w:preview = {'id': l:winid, 'buffer': l:buffer}
endfunction

function! s:VimCreate(options) abort
    let l:popup_id = popup_create([], {
    \    'line': 'cursor+1',
    \    'col': 'cursor',
    \    'drag': v:true,
    \    'resize': v:true,
    \    'close': 'button',
    \    'padding': [0, 1, 0, 1],
    \    'border': [],
    \    'borderchars': empty(g:bibtexcite_floating_window_border) ? [' '] : [
    \        g:bibtexcite_floating_window_border[1],
    \        g:bibtexcite_floating_window_border[0],
    \        g:bibtexcite_floating_window_border[1],
    \        g:bibtexcite_floating_window_border[0],
    \        g:bibtexcite_floating_window_border[2],
    \        g:bibtexcite_floating_window_border[3],
    \        g:bibtexcite_floating_window_border[4],
    \        g:bibtexcite_floating_window_border[5],
    \    ],
    \    'moved': 'any',
    \    })
    call setbufvar(winbufnr(l:popup_id), '&filetype', get(a:options, 'filetype', 'bibtexcite-preview'))
    let w:preview = {'id': l:popup_id}
endfunction

function! s:NvimClose() abort
    let l:mode = mode()
    let l:restore_visual = l:mode is# 'v' || l:mode is# 'V' || l:mode is# "\<C-V>"

    if !exists('w:preview')
        return
    endif

    call setbufvar(w:preview['buffer'], '&modified', 0)

    if win_id2win(w:preview['id']) > 0
        execute win_id2win(w:preview['id']).'wincmd c'
    endif

    unlet w:preview

    if l:restore_visual
        normal! gv
    endif
endfunction

function! s:VimClose() abort
    if !exists('w:preview')
        return
    endif

    call popup_close(w:preview['id'])
    unlet w:preview
endfunction
