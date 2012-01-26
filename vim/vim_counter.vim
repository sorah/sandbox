function! Counter()
    echo len(filter(readfile($MYVIMRC),'v:val !~ "^\\s*$\\|^\\s*\""'))
endfunction

command! Counter :call Counter()
" これでもうごくのよ！　↓
" command! Counter :echo len(filter(readfile($MYVIMRC),'v:val !~ "^\\s*$\\|^\\s*\""'))

