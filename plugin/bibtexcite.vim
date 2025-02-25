" Copyright (c) 2022 Bence Ferdinandy
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:bibtexcite_loaded')
    finish
endif


let g:bibtexcite_loaded = 1
let g:bibtexcite_close_preview_on_insert = get(g:, 'bibtexcite_close_preview_on_insert', 0)
let g:bibtexcite_bibfile = get(g:, 'bibtexcite_bibfile', 0)
let g:bibtexcite_floating_window_border = get(g:, 'bibtexcite_floating_window_border', ['|', '-', '+', '+', '+', '+'])

command! -bang -nargs=? BibtexciteInsert call bibtexcite#fzf(<q-args>,<bang>0)
command! -nargs=? -bang BibtexciteShowcite call bibtexcite#showcite(<q-args>,<bang>0)
command! -nargs=? -bang BibtexciteOpenfile call bibtexcite#openfile(<q-args>,<bang>0)
command! -nargs=? -bang BibtexciteEditfile call bibtexcite#editfile(<q-args>,<bang>0)
command! -nargs=? -bang BibtexciteNote call bibtexcite#note(<q-args>,<bang>0)
