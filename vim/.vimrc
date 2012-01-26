" sorah's vimrc
" Licence: MIT Licence
"   The MIT Licence {{{
"     Permission is hereby granted, free of charge, to any person obtaining a copy
"     of this software and associated documentation files (the "Software"), to deal
"     in the Software without restriction, including without limitation the rights
"     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
"     copies of the Software, and to permit persons to whom the Software is
"     furnished to do so, subject to the following conditions:
"     The above copyright notice and this permission notice shall be included in
"     all copies or substantial portions of the Software.
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
"     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
"     THE SOFTWARE.
"   }}}


" Basic {{{

"set no compatible
set nocompatible

"colorscheme
colorscheme mrkn256

"reset
set runtimepath&
if has('win32') || has('win64')
  set runtimepath+=~/git/config/vim/dot.vim
endif

"pathogen
filetype off
filetype plugin off
filetype plugin indent off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()
set helpfile=$VIMRUNTIME/doc/help.txt
filetype on



"Absorb vimrc/.vim different OSs {{{
if has('win32') || has ('win64')
    set shellslash
    let $VIMFILES = $VIM."/vimfiles"
else
    let $VIMFILES = $HOME."/.vim"
endif
"}}}

"delete all autocmds {{{
autocmd!
"}}}

"view setting {{{
set number

"- -> >>- --->
set list
set listchars=tab:>-,trail:-,extends:>,precedes:<
" }}}

"encoding settings {{{
set enc=utf-8
set fencs=iso-2022-jp,euc-jp,cp932
set ambiwidth=double
set fileformats=unix,dos,mac 

if !has('gui_running') && (&term == 'win32' || &term == 'win64')
    set termencoding=cp932
endif
"}}}

"path setting {{{
if !exists("s:complete_addpath_vimrc") && (&term != 'win32' || &term != 'win64') && has('gui_running')
    let $PATH=$HOME."/local/bin:".$PATH
    let $RUBYLIB=system("ruby -e 'puts (Dir[File.expand_path(\"~/git/ruby/*/lib\")]-Dir[File.expand_path(\"~/git/ruby/{core,ruby}*/lib\")]).join(\":\")'")
    let s:complete_addpath_vimrc=1
endif
"}}}

"search settings {{{
set ignorecase
set smartcase
set wrapscan
set incsearch
set hlsearch
hi Search term=reverse ctermbg=LightBlue ctermfg=NONE
"}}}

"indent settings {{{
set autoindent
set cindent
set tabstop=2
set shiftwidth=2
set smarttab
set expandtab
"}}}

"show other file don't save. {{{
set hidden
"}}}

"command-line settings {{{
set showcmd
set cmdheight=2
set laststatus=2
"set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%{getcwd()}\ [%l,%c]\ %p%%
"}}}

"split {{{
set splitbelow
set splitright
"}}}

"command Tab complement settings {{{
set wildmenu
set wildmode=list:longest
"}}}

"Japanese input etc settings {{{
set noimdisable
set noimcmdline
set iminsert=1
set imsearch=1
"}}}

" Other {{{
set noruler
set nolist
set showmatch
set wrap
set title
set backspace=2
set scrolloff=5
set formatoptions& formatoptions+=mM
set tw=0
let format_join_spaces = 4
let format_allow_over_tw = 1
set nobackup
set history=1000
set mouse=a
set noautochdir
"}}}

"enable filetype plugins {{{
filetype plugin on
filetype plugin indent on
"}}}

"turn on the syntax-highlight {{{
syntax on
" }}}

" search {{{
nmap n nzz
nmap N Nzz
nmap * *zz
nmap # #zz
nmap g* g*zz
nmap g# g#zz
" }}}

"pumheight {{{
set pumheight=6
"}}}

"clipboard {{{
set clipboard=unnamed
"}}}

"printing settings {{{
set printoptions=wrap:y,number:y,header:0
set printfont=Andale\ Mono:h12:cUTF8
"}}}

"fold settings {{{
set foldenable
set foldmethod=marker
set foldcolumn=3
"}}}

"help settings {{{
set helplang=ja
"}}}

lang en_US.UTF-8

"color settings {{{
set t_Co=256
"}}}

"mouse setting {{{
if !has('gui_running')
    set mouse=a
    if exists('$WINDOW')
        set ttymouse=xterm2
    endif
endif
"}}}

"gui {{{
if has('gui_running')
  if has('mac')
    set guifont=Andale\ Mono:h14
    set guifontwide=Menlo:h14
    set columns=131
    set lines=42
    set transparency=15
  endif
  set guioptions-=T
endif
"}}}

" swap is in ~/tmp {{{
set directory-=.
"}}}

" }}}

" autocmd {{{
"Rails etc autocmd {{{
augroup Rails_etc
  autocmd!
  autocmd BufNewFile,BufRead app/*/*.rhtml set ft=mason fenc=utf-8
  autocmd BufNewFile,BufRead app/**/*.rb set ft=ruby fenc=utf-8
  autocmd BufNewFile,BufRead app/**/*.yml set ft=ruby fenc=utf-8
augroup END
"}}}

"input </ to auto close tag on XML {{{
augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
  "autocmd Filetype eruby inoremap <buffer> </ </<C-x><C-o>
augroup END
"}}}

"vimrc auto update {{{
augroup MyAutoCmd
  autocmd!
  autocmd BufWritePost .vimrc nested source $MYVIMRC
  autocmd BufWritePost .vimrc RcbVimrc
augroup END
"}}}

"crontab for Vim {{{
augroup CrontabForVim
  autocmd BufReadPre crontab.* setl nowritebackup
augroup END
"}}}

" ruby - developer {{{
au FileType c set ts=8 sw=4 noexpandtab
au FileType ruby set nowrap tabstop=8 tw=0 sw=2 expandtab
let g:changelog_timeformat = "%c"
let g:changelog_username = "Shota Fukumori (sora_h) <sora134@gmail.com>"
" }}}

"}}}

"vim muscle scouter
"http://d.hatena.ne.jp/thinca/20091031/1257001194
function! Scouter(file, ...)
  let pat = '^\s*$\|^\s*"'
  let lines = readfile(a:file)
  if !a:0 || !a:1
    let lines = split(substitute(join(lines, "\n"), '\n\s*\\', '', 'g'), "\n")
  endif
  return len(filter(lines,'v:val !~ pat'))
endfunction
command! -bar -bang -nargs=? -complete=file Scouter
\        echo Scouter(empty(<q-args>) ? $MYVIMRC : expand(<q-args>), <bang>0)


"hatena.vim settings
set runtimepath+=$VIMFILES/hatena

"neocomplcache settings
let g:neocomplcache_enable_quick_match = 0
let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_underbar_completion = 1
let g:NeoComplCache_enable_info = 1
let g:neocomplcache_enable_smart_case = 1
let g:neocomplcache_manual_completion_start_length = 2
let g:neocomplcache_enable_at_startup = 1 
nnoremap <silent> <C-s> :NeoComplCacheToggle<Return>
nnoremap <silent> <C-d> :NeoComplCacheDisable<Return>

if !exists('g:neocomplcache_include_paths')
    let g:neocomplcache_include_paths = {}
endif
"if has('mac')
"    let g:neocomplcache_include_paths['ruby'] = ".,".$HOME."/local/lib/ruby/**,".$HOME."/rubies/trunk/lib/ruby/**"
"endif

"push C-a to toggle spell check
nnoremap <silent> <C-a> :setl spell!<Return>

"move to line head
nnoremap ~ <Home>
vnoremap ~ <Home>

"key-mapping for edit vimrc
nnoremap <silent> <Space>ev  :<C-u>tabedit $MYVIMRC<CR>
nnoremap <silent> <Space>ee  :<C-u>edit $MYVIMRC<CR>
nnoremap <silent> <Space>eg  :<C-u>edit $MYGVIMRC<CR>
nnoremap <silent> <Space>ea  :source $MYVIMRC<Return>

"key-mapping for shift-n
nnoremap m N

"markdown.vim setting
if filereadable("/Users/sorah/local/bin/markdown.pl")
    let g:markdownPathToMarkdown = "/Users/sorah/local/bin/markdown.pl"
endif

nnoremap <C-h> :<C-u>vertical help<Space>

"replace shortcut
nnoremap // :<C-u>%s/
vnoremap // :s/
nnoremap ? :<C-u>let @/ = ""<CR>

"quickrun.vim settings
if !exists('g:quickrun_config')
  let g:quickrun_config = {'*': { 'split': 'vertical rightbelow', 'runmode': 'async:remote:vimproc'}}
  let g:quickrun_config.markdown = {'exec' : 'function __mkd__() { markdown.pl $1 > /tmp/__markdown.html && open /tmp/__markdown.html } && __mkd__'}
  let g:quickrun_config.markdown = {'exec' : ['pandoc -f markdown -t html -o /tmp/markdown.html %s', 'open /tmp/markdown.html']}
  let g:quickrun_config.actionscript = {'exec' : ['mxmlc -output /tmp/__as.swf -default-background-color 0xFFFFFF %s', 'open /tmp/__as.swf']}
  let g:quickrun_config.coffee = {'command': 'coffee'}
endif

"split shortcut
nnoremap <silent> <C-w>l <C-w>l:call <SID>Goodwidth()<Cr>
nnoremap <silent> <C-w>h <C-w>h:call <SID>Goodwidth()<Cr>

nnoremap sl <C-w>l:call <SID>Goodwidth()<Cr>
nnoremap sh <C-w>h:call <SID>Goodwidth()<Cr>
nnoremap sj <C-w>j:call <SID>Goodwidth()<Cr>
nnoremap sk <C-w>k:call <SID>Goodwidth()<Cr>
nnoremap sL <C-w>L
nnoremap sH <C-w>H
nnoremap sJ <C-w>J
nnoremap sK <C-w>K

"auto adjust a split window width
"http://vim-users.jp/2009/07/hack42/
function! s:Goodwidth()
  if winwidth(0) < 84
    vertical resize 90
  endif
endfunction


"tab shortcut
nnoremap <silent> tn :tabn<Cr>
nnoremap <silent> tp :tabp<Cr>
nnoremap <silent> tb :tabp<Cr>
nnoremap <silent> te :tabe<Cr>

"align.vim
let g:Align_xstrlen=3

"th :tabe ~/
nnoremap th :tabe ~/
nnoremap ts :tabe ~/sandbox/
nnoremap m  :tabe ~/sandbox/
nnoremap tr :tabe ~/sandbox/ruby/
nnoremap tt :tabe ~/git/ruby/termtter/
nnoremap tg :tabe ~/git
nnoremap eh :e ~/
nnoremap es :e ~/sandbox/
nnoremap er :e ~/sandbox/ruby/
nnoremap et :e ~/git/ruby/termtter/
nnoremap eg :e ~/git

"q -> C-o
nnoremap q <C-o>

"super jump
nnoremap H 5h
nnoremap L 5l
nnoremap J <C-f>
nnoremap K <C-b>

"C-r U"
nnoremap U <C-r>

", <$
nnoremap , <$
nnoremap . >$

"; dd
nnoremap ; dd

"- gg=G
nnoremap - gg=G
vnoremap - =

" unite.vim
nnoremap <C-z> :<C-u>Unite file_rec<Cr>
" unite-neco {{{
let s:unite_source = {'name': 'neco'}

function! s:unite_source.gather_candidates(args, context)
  let necos = [
        \ "~(-'_'-) goes right",
        \ "~(-'_'-) goes right and left",
        \ "~(-'_'-) goes right quickly",
        \ "~(-'_'-) skips right",
        \ "~(-'_'-)  -8(*'_'*) go right and left",
        \ "(=' .' ) ~w",
        \ ]
  return map(necos, '{
        \ "word": v:val,
        \ "source": "neco",
        \ "kind": "command",
        \ "action__command": "Neco " . v:key,
        \ }')
endfunction

"function! unite#sources#locate#define()
"  return executable('locate') ? s:unite_source : []
"endfunction
call unite#define_source(s:unite_source)

" }}}

"rb
if has('mac')
  if !exists('g:rb_vimrc_done')
    let $PATH=$HOME."/rubies/bin:".$PATH
  endif
  let g:rb_vimrc_done=1
endif

"vimproc
if has('mac')
  let g:vimproc_dll_path=$VIMFILES."/autoload/proc.osx.so"
endif

" Disable bell.
set visualbell
set vb t_vb=

"vimshell
let g:vimshell_execute_file_list = {}
if has('win32') || has('win64')
  " Display user name on Windows.
  let g:vimshell_prompt = $USERNAME."@".hostname()."% "
elseif has('mac') || has('unix')
  " Display user name on Linux.
  let g:vimshell_prompt = $USER.'@'.hostname()."% "
  let g:vimshell_user_prompt = 'fnamemodify(getcwd(), ":~")'
  call vimshell#set_execute_file('bmp,jpg,png,gif,mp3,m4a,ogg', 'open')
  let g:vimshell_execute_file_list['zip'] = 'zipinfo'
  call vimshell#set_execute_file('tgz,gz', 'gzcat')
  call vimshell#set_execute_file('tbz,bz2', 'bzcat')
endif



" Initialize execute file list.
call vimshell#set_execute_file('txt,vim,c,h,cpp,d,xml,java', 'vim')
let g:vimshell_execute_file_list['rb'] = 'ruby'
let g:vimshell_execute_file_list['pl'] = 'perl'
let g:vimshell_execute_file_list['py'] = 'python'
if has('win32') || has('win64')
  call vimshell#set_execute_file('html,xhtml', 'start')
elseif has('mac')
  call vimshell#set_execute_file('html,xhtml', 'open')
else
  call vimshell#set_execute_file('html,xhtml', 'firefox')
end

let g:VimShell_enable_interactive = 1
let g:VimShell_enable_smart_case = 1

":cdd => :Cdd
cabbrev cdd Cdd

"Setf
nnoremap <C-s> :<C-u>setf 

"mv editing file
function! g:MvEditingFile(new_file_name)
  call system("mv".expand('%')." ".a:new_file_name)
  e a:new_file_name
endfunction
command! -nargs=1 Rename call g:MvEditingFile(<f-args>)

"chdir to now dir
"http://vim-users.jp/2009/09/hack69/
command! -nargs=? -complete=dir -bang CD  call s:ChangeCurrentDir('<args>', '<bang>') 

function! s:ChangeCurrentDir(directory, bang)
    if a:directory == ''
        lcd %:p:h
    else
        execute 'lcd' . a:directory
    endif

    if a:bang == ''
        pwd
    endif
endfunction

nnoremap <silent> <Space>cd :<C-u>CD!<CR>

"rsense
"http://vinarian.blogspot.com/2010/03/rsenseneocomplcache.html
let g:rsenseHome = $HOME.'/local/opt/rsense'
let g:rsenseUseOmniFunc = 1

"snip
imap <silent><C-a> <Plug>(neocomplcache_snippets_expand)

"gist.vim
if has('mac')
  let g:gist_clip_command = 'pbcopy'
endif

"compl
inoremap <expr> ] searchpair('\[', '', '\]', 'nbW', 'synIDattr(synID(line("."), col("."), 1), "name") =~? "String"') ? ']' : "\<C-n>"

"vimfiler
let g:vimfiler_execute_file_list = {}
let g:vimfiler_execute_file_list['rb'] = 'ruby'
let g:vimfiler_execute_file_list['pl'] = 'perl'
let g:vimfiler_execute_file_list['py'] = 'python'
let g:vimfiler_edit_command = 'tabe'
let g:vimfiler_split_command = ''
if has('mac')
  let g:vimfiler_execute_file_list['html'] = 'open'
  let g:vimfiler_execute_file_list['htm'] = 'open'
  let g:vimfiler_execute_file_list['xhtml'] = 'open'
elseif has('win32') || has('win64')
  let g:vimfiler_execute_file_list['html'] = 'open'
  let g:vimfiler_execute_file_list['htm'] = 'open'
  let g:vimfiler_execute_file_list['xhtml'] = 'open'
endif


"ew
function! g:VimRcWriteEdit()
  write
  edit
endfunction
command! WriteEdit call g:VimRcWriteEdit()
cabbrev we WriteEdit

"open
function! g:CallOpenCmd(...)
  if a:0 > 0
    if has('mac')
      call system("open ".shellescape(a:1))
    else
      call system("gnome-open ".shellescape(a:1))
    endif
  else
    if has('mac')
      call system("open ".shellescape(expand('%:p')))
    else
      call system("gnome-open ".shellescape(expand('%:p')))
    endif
  endif
endfunction
command! -nargs=? -complete=file Open call g:CallOpenCmd('<args>')

"few
function! g:Few(...)
  if a:0 > 0
    call system("few ".shellescape(expand(a:1)))
  else
    echomsg "hi"
    call system("few ".shellescape(expand('%:p')))
  endif
endfunction
command! -nargs=? -complete=file Few call g:Few('<args>')

"notes
let g:notes_dir_path=expand("~")."/sandbox/document/memo"
function! g:OpenNotes(fn)
   execute ":tabe ".expand(g:notes_dir_path."/".a:fn.".mkd")
endfunction
function! OpenNoteHkn(a,b,c)
  return substitute(system("ls -1 ". shellescape(g:notes_dir_path)), ".mkd", "", "g")
endfunction
command! -nargs=1 -complete=custom,OpenNoteHkn Note call g:OpenNotes(<q-args>)
nnoremap <C-e> :<C-u>Note 

" RSpec
function! g:QuickRunRSpecWithoutLine()
  let g:quickrun_config['ruby.rspec'] = {'command': 'rspec'}
endfunction
function! g:QuickRunRSpecWithLine()
  let g:quickrun_config['ruby.rspec'] = {'command': "rspec -l {line('.')}"}
endfunction
call g:QuickRunRSpecWithoutLine()
command! QuickRSpecWithLine call g:QuickRunRSpecWithLine()
command! QuickRSpec call g:QuickRunRSpecWithoutLine()
augroup UjihisaRSpec
  autocmd!
  autocmd BufWinEnter,BufNewFile *_spec.rb set filetype=ruby.rspec
augroup END



"read other vimrc files
if filereadable($VIMFILES."/other/private.vim")
    source $VIMFILES/other/private.vim
endif

