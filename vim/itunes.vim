" itunes.vim
" Author: Sora Harakami <sora134@gmail.com>
" Licence: MIT Licence
" Require: Mac OS X (this script using osascript.)

if exists('g:loaded_itunesvim')
    finish
endif
let g:loaded_itunesvim = 1
let s:save_cpo = &cpo
set cpo&vim

function! s:Command_itunes(c)
    call system("osascript -e 'tell application \"iTunes\" to ".a:c."'")
    call s:Now_playing_on_itunes()
endfunction

function! s:Now_playing_on_itunes()
    echo system("osascript -e 'tell application \"iTunes\"\nset str to {name of current track, \" - \", album of current track, \" (\", artist of current track, \")\"}\nreturn str as text\nend tell'")
endfunction

command! PlayiTunes :call s:Command_itunes("play")
command! StopiTunes :call s:Command_itunes("stop")
command! ToggleiTunes :call s:Command_itunes("playpause")
command! PauseiTunes :call s:Command_itunes("pause")
command! PreviTunes :call s:Command_itunes("previous track")
command! BackiTunes :call s:Command_itunes("back track")
command! NextiTunes :call s:Command_itunes("next track")
command! StatusiTunes :call s:Now_playing_on_itunes()

let &cpo = s:save_cpo
unlet s:save_cpo
