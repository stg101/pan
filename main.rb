# frozen_string_literal: true

class Pintor
  def initialize
    @color_code = rand(1..231)
  end

  def paint(text)
    "\u001b[38;5;#{@color_code}m#{text}\u001b[0m"
  end

  def reset_color
    @color_code = rand(1..231)
  end
end

def add_edges(event)
  node = get_node_name(event)
  edge = [@stack.last, node]

  @stack << node
  @edges << edge
end

def get_node_name(event)
  "#{event.defined_class}##{event.method_id} #{event.path}"
end

def build_tracer(prefix = '')
  TracePoint.new(:call, :return) do |event|
    next if event.defined_class == self.class

    next unless event.path.include? prefix

    case event.event
    when :return
      @stack.pop
    when :call
      add_edges(event)
    end
  end
end

def draw_trace
  active_nodes = []
  node_pintors = {}
  @edges.unshift [nil, @edges[0].first]

  @edges.each_with_index do |edge, index|
    if active_nodes.last == edge.first
      base = ''
      active_nodes.each do |node|
        p = node_pintors[node]
        base += p.paint('| ')
      end

      puts base + "*  #{edge.last}"
    else

      # change of branch
      if @edges[index - 1].last != edge.first
        while active_nodes.pop != edge.first && !active_nodes.empty?
        end
      end

      base = ''
      active_nodes.each do |node|
        p = node_pintors[node]
        base += p.paint('| ')
      end

      active_nodes << edge.first
      node_pintors[edge.first] ||= Pintor.new
      node_pintors[edge.last] ||= Pintor.new

      fp = node_pintors[active_nodes.last]
      lp = node_pintors[edge.last]
      puts base + fp.paint('|') + lp.paint('\\')
      puts base + fp.paint('| ') + "*  #{edge.last}"
    end
  end
end

def pan()
  unless block_given?
    puts 'Block required!'
    return
  end

  @stack = ['start']
  @edges = []
  tracer ||= build_tracer

  tracer.enable
  yield
  tracer.disable

  draw_trace
  nil
end

## test

module Foo
  module_function

  def aaa
    bbb
    ccc
  end

  def bbb
    ccc
    ccc
    ccc
    ccc
  end

  def ccc; end
end

pan { Foo.aaa }
# @edges = [%w[start aaa], %w[start bbb], %w[start ccc]]
# @edges = [%w[start aaa], %w[start bbb], %w[bbb ccc], %w[start ccc]]
# @edges = [%w[start aaa]]
# puts @edges.to_s
