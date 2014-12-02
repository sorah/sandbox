sources = [
  Dir['/Users/sorah/Downloads/gifs2/*'],
  Dir['/Users/sorah/Downloads/gifs3/*'],
  '/Users/sorah/Downloads/gifs',
  '/Users/sorah/Downloads/gif_maenox',
  '/Users/sorah/Pictures/gifs',
].flatten

destdir = '/tmp/gifs'

loop do
  processed = {}
  sources.each do |source|
    gifs = Dir[File.join(source, '**/*.gif')]
    gifs.each do |gif|
      base = File.basename(gif)
      next if processed[base]
      dest = File.join(destdir, base)
      processed[base] = true


      if File.symlink?(dest)
        if !File.exist?(dest) || (File.realpath(dest) != File.realpath(gif))
          File.unlink dest
        else
          next
        end
      end

      File.symlink gif, dest
      p [gif, dest]
    end
  end

  sleep 2
end

