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
    h = Ev.winheight(Ev.winnr) - 2
    w = Ev.winwidth(Ev.winnr)
    remaining_h = h - ft.h
    Ex.set "foldmethod=manual"
    N.zE
    Rex.fold 1, ft.fl-1
    Rex.fold ft.ll+1, '$'
    N["#{ft.fl}ggztzszM"]
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
      Ex.set "foldmethod=manual"
      N.zE
      Rex.fold 1, b.fl-1
      Rex.fold b.ll+1, '$'
      N["#{b.fl}ggztzszM"]
    end
    window_columns.each do |ws|
      ws[..-2].each do |w|
        Rex1.wincmd w.id, 'w'
        Ex.resize w.h
        N.ztzs
      end
      Rex1.wincmd ws.last.id, 'w'
      N.ztzs
    end
    Ex.redraw!
  end
end
RUBY
endfu

if exists('g:nyao_always_add_mappings') && g:nyao_always_add_mappings
  vno <nowait> \d :ruby NyaoDirector.global.add_block<CR>
  nno <nowait> \d :ruby NyaoDirector.global.show<CR>
  nno <nowait> \r :ruby NyaoDirector.global.reset<CR>
endif

call s:setup()
