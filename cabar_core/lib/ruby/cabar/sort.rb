
require 'cabar_core'

module Cabar

  # Sorting functions.
  module Sort

    # Takes a list of elements and :dependents => Proc { | element | ... } option.
    #
    # Returns elements sorted such that any element e1 will be
    # after e2 if e1 is in dependents.call(e2) decendents.
    #
    # The :dependents Proc is is expected to return an Enumerable.
    #
    # Should complete even if dependency graph is cyclical.
    #
    # Elements at the same dependency level will be sorted by an :order => Proc { | a, b | ... } option.
    # The :order Proc defaults to produce a stable sort based on the input.
    #
    def topographic_sort elements, opts = EMPTY_HASH
      # Get a Proc that returns the dependents of an element.
      # The proc must return an enumeration that can be perform :reverse.
      dependents_proc = opts[:dependents] || raise("No :dependents option")

      # Depth of each node during recursion.
      depth = { }

      # Recur on each node's subgraph starting at depth 0.
      elements.each do | node |
        _topo_visit(node, dependents_proc, 0, depth, { })
      end

      # Create a tie-breaker ordering proc
      # that returns -1, 0, 1 for two elements.
      #
      # The default ordering proc will produce a stable sort
      # of the input.
      order = nil
      order_proc = opts[:order] || lambda do | x, y |
        order ||=
          elements.inject({ }) { | h, e | h[e] ||= h.size; h }
        order[x] <=> order[y]
      end
 
      # Sort the elements by relative depth or tie-breaker ordering.
      result = elements.sort do | a, b | 
        # $stderr.puts "a = #{a.inspect}"
        # $stderr.puts "b = #{b.inspect}"
        case
        when (x = depth[a] <=> depth[b]) != 0
          x
        when (x = order_proc.call(a, b)) != 0
          x
        else
          0
        end
      end

      if opts[:debug]
        require 'pp'; 
        puts "elements = "; pp elements
        puts "result = "; pp result
        puts "depth = "; pp depth.to_a.sort_by{|x| x[1]}
      end

      result
    end


    def _topo_visit node, children, depth, depths, visited
      if ! visited[node] 
        # For this subgraph, mark node as visited.
        visited = visited.dup
        visited[node] = true

        # If node has not assigned a depth,
        #   Assign it to this recursion depth.
        d_n = (depths[node] ||= depth)

        # If node was at a depth higher than
        # the current depth, 
        #   Move it to a lower depth.
        if d_n < depth
          d_n = depths[node] = depth
        end

        # Place all node's dependents lower than it's depth.
        depth_1 = d_n + 1

        # Recur on node's children.
        children.call(node).each do | child |
          _topo_visit(child, children, depth_1, depths, visited)
        end
      end
    end
    private :_topo_visit


    # Returns the topographically sorted subset of all nodes in a directed graph.
    # all_elements must list all the nodes in the directed graph.
    def topographic_sort_subset subset, all_nodes, opts = nil
      topographic_sort(all_nodes, opts) & subset
    end

  end # module

end # module

