nnoremap <C-y> :call <SID>PostTwitter()
function! s:PostTwitter()
    ruby post_to_twitter
endfunction

ruby << EOF
require 'rubytter'
require 'yaml'
def post_to_twitter
   config = open(ENV["HOME"]+"/.twitter"){|f|YAML.parse(f.read)}
   
end
EOF
