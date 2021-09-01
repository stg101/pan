# frozen_string_literal: true

class Pintor
  def initialize
    @color_code = rand(80..230)
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

  attr_accessor :state, :name, :pintor, :parent

  def initialize(name = '', state: STATES[:initial], parent: nil)
    @state = state
    @pintor = Pintor.new
    @name = name
    @parent = parent
  end

  def draw
    @pintor.paint(@name)
    parent_pintor = @parent&.pintor || Pintor.new

    case @state
    when STATES[:initial]
      print parent_pintor.paint('>') + " #{@name}"
    when STATES[:active]
      print @pintor.paint('  |')
    else
      print ''
    end
  end

  def ==(other)
    name == other.name
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
  start = Node.new('', state: 'active')
  branches = [start]
  @edges[0].first.parent = start
  @edges.unshift [start, @edges[0].first]

  @edges.each_with_index do |edge, _index|
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
  node_name = "#{event.self} #{event.defined_class}##{event.method_id}"
  node = Node.new(node_name, parent: @stack.last)
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

def pan(prefix: '')
  unless block_given?
    puts 'Block required!'
    return
  end

  @stack = [Node.new('start')]
  @edges = []
  tracer ||= build_tracer(prefix)

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

# Output :
# |> start
# |  |> Foo #<Class:Foo>#aaa
# |  |  |> Foo #<Class:Foo>#bbb
# |  |  |  |> Foo #<Class:Foo>#ccc
# |  |  |  |> Foo #<Class:Foo>#ccc
# |  |  |  |> Foo #<Class:Foo>#ccc
# |  |  |  |> Foo #<Class:Foo>#ccc
# |  |  |> Foo #<Class:Foo>#ccc
# |  |> #<TracePoint:0x0000555bf582cb60> TracePoint#disable
