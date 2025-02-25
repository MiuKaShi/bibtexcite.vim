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

let s:cpo_save = &cpo
set cpo&vim

function! bibtexcite#pandoc_sink(lines)
    let r=system("bibtex-cite --mode=pandoc", a:lines)
    execute ':normal! a' . r
endfunction

function! bibtexcite#latex_sink(lines)
    let r=system("bibtex-cite --mode=latex", a:lines)
    execute ':normal! a' . r
endfunction

function! bibtexcite#markdown_sink(lines)
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
    let r=system("bibtex-markdown " . l:bibtexcite_bibfile . " ", a:lines )
    execute ':normal! a' . r
endfunction

function! bibtexcite#get_bibfile()
    let l:bibtexcite_bibfile = get(b:, 'bibtexcite_bibfile',g:bibtexcite_bibfile)
    if type(l:bibtexcite_bibfile) == v:t_list
        let l:bibtexcite_bibfile = join(l:bibtexcite_bibfile)
    endif
    return l:bibtexcite_bibfile
endfunction

function! bibtexcite#fzf(citetype = "pandoc", bang = 0)
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
    if a:citetype ==? "pandoc" || a:citetype == ""
        let sink = 'bibtexcite#pandoc_sink'
        let prompt = '"Cite pandoc>"'
    elseif a:citetype ==? "latex"
        let sink = 'bibtexcite#latex_sink'
        let prompt = '"Cite latex>"'
    elseif a:citetype ==? "markdown"
        let sink = 'bibtexcite#markdown_sink'
        let prompt = '"Cite markdown>"'
    else
        echo "bad citetype"
        return 0
    endif

    call fzf#run({
        \ 'source': 'bibtex-ls ' . l:bibtexcite_bibfile,
        \ 'sink*': function(sink),
        \ 'up': '40%',
        \ 'options': '--exact --ansi --layout=reverse-list --multi --prompt '. prompt},
        \ a:bang)
endfunction

function! bibtexcite#getcitekey(citetype = "pandoc", bang = 0)
    if a:bang
        let word = expand("<cWORD>")
        return word
    endif
    if a:citetype ==? "pandoc" || a:citetype == ""
        let word = expand("<cWORD>")
        let regex = '@\<\([a-zA-Z0-9\-&_]\+\)\>;\?'
        if word =~ regex
            let word = substitute(word, regex, '\1', '')
            let word = substitute(word, ';','','')
            let word = substitute(word, ',','','')
            let word = substitute(word, '\.','','')
            return word
        else
            return 0
        endif
    elseif a:citetype ==? "latex"
        let line=getline('.')
        if line =~ '\\cite{[a-zA-Z0-9\-&_, ]\+}'
            let word = expand("<cWORD>")
            let regex = '@\<\([a-zA-Z0-9\-&_]\+\)\>,\?'
            let word = substitute(word, regex, '\1', '')
            let word = substitute(word, '\\cite{','','')
            let word = substitute(word, ',','','')
            let word = substitute(word, '}','','')
            return word
        else
            return 0
        endif
    else
        echo "bad citetype"
        return 0
    endif
endfunction

function! bibtexcite#getcite(citetype = "pandoc", bang = 0)
    let citekey = bibtexcite#getcitekey(a:citetype, a:bang)
    if len(citekey) == 1
        return 0
    endif
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
	let bib  = system('bib-extract ' . l:bibtexcite_bibfile . ' ' . citekey)
    " let bib = system("bibtool -r biblatex -X " . citekey . "$ " . l:bibtexcite_bibfile)
    if len(bib) == 0
        echo "no citation found"
        return 0
    else
        if has('nvim')
            return join(split(bib,"\t"), "  ")
        else
            return bib
        endif
    endif
endfunction

function! bibtexcite#showcite(citetype = "pandoc", bang = 0)
    let bib = bibtexcite#getcite(a:citetype, a:bang)
	let bib = system("bib-txt -", bib)
	let @+=bib
	let bib = system("fold -s -w 50", bib)
    if len(bib) > 1
        call bibtexcite#floating_preview#Show(split(bib,'\n'))
    endif
endfunction

function! bibtexcite#openfile(citetype = "pandoc", bang = 0)
    let citekey = bibtexcite#getcitekey(a:citetype, a:bang)
    call jobstart("dmenupaper " . citekey . " ")
endfunction

function! bibtexcite#editfile(citetype = "pandoc", bang = 0)
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
    let citekey = bibtexcite#getcitekey(a:citetype, a:bang)
	call jobstart('bib-edit ' . l:bibtexcite_bibfile . ' ' . citekey)
endfunction

function! bibtexcite#note(citetype = "pandoc", bang = 0)
    let citekey = bibtexcite#getcitekey(a:citetype, a:bang)
    call jobstart("bib-note " . citekey . " ")
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
