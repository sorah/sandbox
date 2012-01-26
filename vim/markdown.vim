" markdown.vim
" Author: Sora Harakami <sora134[at]gmail.com>
" Require: markdown.pl http://daringfireball.net/projects/markdown/
" Licence: MIT Licence

if exists("g:markdownVimIsLoaded")
    finish
endif
let g:markdownVimIsLoaded = 1
if !exists("g:markdownPathToMarkdown")
    let g:markdownPathToMarkdown = "markdown.pl"
endif
let s:save_cpo = &cpo
set cpo&vim

function! MarkDown()
    " FIXME: qqa228CRqqqq
    let markdown = substitute(shellescape(join(getline(0,line("$")),"qqa228CRqqqq")),"qqa228CRqqqq","\n","g") 
    let tmpmd = system("echo ".markdown."|".g:markdownPathToMarkdown." >/tmp/__mdvim_markdown.html")
    tabe /tmp/__mdvim_markdown.html
endfunction

command! MarkDown :call MarkDown()

let &cpo = s:save_cpo
unlet s:save_cpo

