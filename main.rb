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

class Node
  STATES = {
    initial: 'initial',
    active: 'active'
  }.freeze

  attr_accessor :state, :name

  def initialize(name = '', state = STATES[:initial])
    @state = state
    @pintor = Pintor.new
    @name = name
  end

  def draw
    @pintor.paint(@name)

    case @state
    when STATES[:initial]
      print @pintor.paint('->>') + " #{@name}"
    when STATES[:active]
      print @pintor.paint('  |')
    else
      print ''
    end
  end

  def ==(other)
    name == other.name
  end

  def !=(other)
    name != other.name
  end

  def next_state
    case @state
    when STATES[:initial]
      @state = STATES[:active]
    when STATES[:active]
      @state = STATES[:active]
    end
  end
end

def draw_trace
  start = Node.new('', 'active')
  branches = [start]
  @edges.unshift [start, @edges[0].first]

  @edges.each_with_index do |edge, _index|
    # p branches.map(&:name)
    # p edge.map(&:name)

    branches.pop while edge.first != branches.last

    branches << edge.last

    branches.each do |node|
      node.draw
      node.next_state
    end
    puts ''
  end
end

def add_edges(event)
  node_name = "#{event.defined_class}##{event.method_id} #{event.path}"
  node = Node.new(node_name)
  edge = [@stack.last, node]

  @stack << node
  @edges << edge
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

def pan
  unless block_given?
    puts 'Block required!'
    return
  end

  @stack = [Node.new('start')]
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

# @edges = [
#   [Node.new('start'), Node.new('aaa')],
#   [Node.new('start'), Node.new('bbb')],
#   [Node.new('bbb'), Node.new('ccc')],
#   [Node.new('start'), Node.new('ccc')]
# ]
# draw_trace
# puts @edges.to_s
