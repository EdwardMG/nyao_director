fu! s:setup()
ruby << RUBY
class NyaoDirector
  attr_accessor :blocks

  # path, first line, last line, height
  Block = Struct.new(:path, :fl, :ll, :h)

  def initialize
    @blocks = []
  end

  def self.global
    $nyao_director = defined?($nyao_director) ? $nyao_director : NyaoDirector.new
  end

  def reset
    @blocks = []
  end

  def add_block
    visual_selection = VisualSelection.new
    @blocks << Block.new(
      Ev.expand('%:p'),
      visual_selection.l.lnum,
      visual_selection.r.lnum,
      visual_selection.r.lnum - visual_selection.l.lnum + 1
    )
  end

  Window = Struct.new(:id, :h)
  def show
    raise "Nothing to show" unless blocks.any?
    ft = blocks.first
    raise "#{ft.path} doesn't exist." unless File.exist? ft.path
    window_columns = []
    Ex.tabedit ft.path
    window_columns << [Window.new(Ev.winnr, ft.h)]
    h = Ev.winheight(Ev.winnr)
    w = Ev.winwidth(Ev.winnr)
    remaining_h = h - ft.h
    Ex["1,#{ft.fl-1}fold"]
    Ex["#{ft.ll+1},$fold"]
    Ex.normal! "#{ft.fl}ggzt"
    blocks[1..].each do |b|
      raise "#{b.path} doesn't exist." unless File.exist? b.path
      remaining_h -= b.h
      if remaining_h > -1
        Ex.sp b.path
      else
        remaining_h = h - b.h
        Ex.vert "vert botright split #{b.path}"
        window_columns << []
      end
      window_columns.last << Window.new(Ev.winnr, b.h)
      remaining_h = h - b.h
      Ex.normal! "zE"
      Ex["1,#{b.fl-1}fold"]
      Ex["#{b.ll+1},$fold"]
      Ex.normal! "#{b.fl}ggzt"
    end
    window_columns.each do |ws|
      ws[..-2].each do |w|
        Ex["#{w.id}wincmd w"]
        Ex.resize w.h
        Ex.normal! "zt"
      end
      Ex["#{ws.last.id}wincmd w"]
      Ex.normal! "zt"
    end
  end
end
RUBY
endfu

vno <nowait> \d :ruby NyaoDirector.global.add_block<CR>
nno <nowait> \d :ruby NyaoDirector.global.show<CR>
nno <nowait> \r :ruby NyaoDirector.global.reset<CR>

call s:setup()
