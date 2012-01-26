function! Gist()
    let nowfile = expand("%:p")
    echo system("/plagger/bin/gist < ".nowfile."|pbcopy")
endfunction
command! Gist :call Gist()
