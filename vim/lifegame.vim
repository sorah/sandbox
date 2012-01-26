" Lifegame for vim.
" Version: 0.1.0
" Author : thinca <http://d.hatena.ne.jp/thinca/>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_lifegame') || v:version < 702
  finish
endif
let g:loaded_lifegame = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:lifegame()
  tabnew
  let width = winwidth('%')
  let height = winheight('%')

  call append(1, map(range(height), 'repeat(" ", width)'))
  1 delete _

  command! -buffer Start call s:start()
  nnoremap <buffer> <silent> <Space> :<C-u>call <SID>toggle()<CR>
  setlocal nolist
endfunction



function! s:toggle()
  let char = getline('.')[col('.') - 1]
  execute 'normal!' 'r' . (char == ' ' ? '*' : ' ')
endfunction



function! s:start()
  while 1
    let before = []

    for i in getline(1, '$')
      call add(before, map(split(i, '.\zs'), 'v:val != " "'))
    endfor

    let [width, height] = [len(before), len(before[0])]
    let after = deepcopy(before)

    let g:before = deepcopy(before)

    for i in range(width)
      for j in range(height)
        let c = before[i][j]
        let alive = s:around(before, i, j)
        let after[i][j] = (c == 0 && alive == 3) || (c == 1 && (alive == 2 || alive == 3))
      endfor
    endfor

    for i in range(len(after))
      call setline(i + 1, join(map(after[i], 'v:val ? "*" : " "'), ''))
    endfor

    redraw!
    sleep 100ms
  endwhile
endfunction


function! s:around(cells, x, y)
  let [width, height] = [len(a:cells), len(a:cells[0])]
  let cnt = 0
  for i in range(a:x - 1, a:x + 1)
    for j in range(a:y - 1, a:y + 1)
      if i == a:x && j == a:y
        continue
      endif
      if i < 0
        let i = width - 1
      endif
      if j < 0
        let j = height - 1
      endif
      if width <= i
        let i = 0
      endif
      if height <= j
        let j = 0
      endif
      if a:cells[i][j]
        let cnt += 1
      endif
    endfor
  endfor
  return cnt
endfunction


command! Lifegame call s:lifegame()

let &cpo = s:save_cpo
unlet s:save_cpo