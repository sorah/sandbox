" yet another mixi.vim - post to japanese cozy social networking system
" Version: 15
" Author: sorah <http://codnote.net>
" Licence: MIT Licence
" ChangeLog:
"    Version1:  first release.
"    Version15: supported |:w| command, not require |+ruby|, but require |ruby|.
"    Version2:  supported publish range. 
" HowToUse: 
"    [REQUIRE]
"       - library |wsse| (|gem install wsse|)
"       - |ruby| (not |+ruby|)
"    [NEW POST]
"       |:Mixi|
"       Title is line 1 or line 2.
"       If you put publish-range setting to line 1, title is line 2.
"       Then, run |:MixiPost| or |:w| to post.
"    [PUBLISH-RANGE-SETTING]
"       Put setting to line 1. Title is line 2.
"       Setting is this:
"           publish-range: RANGE
"       RANGE is:
"           - default                           / mixi default setting
"           - open, all, public                 / publish to all mixi user
"           - close, me_only, not_public        / don't publish         (me)
"           - mymixi, friend                    / publish to friend.    (me-friend)
"           - 2mymixis, 2friends, friend_friend / publish to 2 friends. (me-friend-friend)
"             
"    [POST]
"       |:w| or |:MixiPost|
"    [CONFIG]
"       |~/.mixi|
"       line 1: mixi mail address
"       line 2: mixi password
"       line 3: mixi member id (so number)
"    [MIXI ECHO & IMAGE]
"       never not supported.
"       sorry :(

let s:mixi_rb_cmd = printf('ruby %s/mixi.rb', expand('<sfile>:p:h'))

command! MixiPost call <SID>MixiPostCmd()
command! Mixi call <SID>MixiStart()

function! s:MixiStart()
    let s:mixi_tempfile = tempname()
    execute 'edit! ' . s:mixi_tempfile
    autocmd BufWritePost <buffer> call <SID>MixiPostCmd()
endfunction

function! s:MixiPostCmd()
    if confirm("really?") != 0
        echo "Posting..."
        "
        "ruby mixi_run
        let s:result = <SID>MixiPost()

        bdelete
        if s:result == "0"
            echo "Posted successfully."
        else
            echo s:result
        endif
    else
        echo "Post cancelled."
    endif
endfunction

function! s:MixiPost()
    if !executable('ruby')
        return "ERROR: This script needs Ruby."
    endif
    if !exists('s:mixi_tempfile')
        return "ERROR: not exists s:mixi_tempfile"
    endif

    write

    let result = system(s:mixi_rb_cmd . " " . s:mixi_tempfile)
    unlet s:mixi_tempfile

    return result
endfunction
