
require 'cabar_core'

module Cabar

  # Sorting functions.
  module Sort

    # Takes a list of elements and :dependents => Proc { | element | ... } option.
    #
    # Will sort elements such that any element e1 will be
    # after e2 if e1 is in dependents.call(e2) decendents.
    #
    # dependents Proc is is expected to return an Enumerable
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

      # The depth of given element in the graph.
      # Each element starts at 1
      depth = { }
      elements.each { | e | depth[e] = 1 }
      
      # Avoid cyclical edges.
      edge_visited = { }

      # The queue containing each element and its current depth.
      queue = elements.dup
      queue_size = queue.size

      # Until the queue is empty,
      until queue.empty?
        # Get the element.
        e = queue.shift
        
        # Put dependents lower than than current node.
        d = depth[e] + 1
        
        dependents = dependents_proc.call(e)
        dependents = dependents.select do | c |
          # Update dependent's depth.
          if ! depth[c] || (depth[c] < d)
            depth[c] = d
          end

          # Was edge visited before?
          edge = [ e, c ].freeze
          if (v = edge_visited[edge]) && (v > queue_size) # heuristic
            # Do not place on queue again.
            false
          else
            # Mark edge as visited.
            edge_visited[edge] ||= 0
            edge_visited[edge] += 1
          end
        end

        # Put remaining dependents at front of queue.
        queue[0, 0] = dependents
        # queue.push(*dependents)
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
      
      # $stderr.puts "elements = #{elements.inspect}"
      # $stderr.puts "depth = #{depth.inspect}"
      # $stderr.puts "order = #{get_order.call.inspect}"
      
      # Sort the elements by relative depth or tie-breaker ordering.
      result = elements.sort do | a, b | 
        # $stderr.puts "a = #{a.inspect}"
        # $stderr.puts "b = #{b.inspect}"
        if (x = depth[a] <=> depth[b]) != 0
          x
        elsif (x = order_proc.call(a, b)) != 0
          x
        else
          0
        end
      end
      
      result
    end
    #module_method :sort_topographic


    # Returns the topographically sorted subset of all nodes in a directed graph.
    # all_elements must list all the nodes in the directed graph.
    def topographic_sort_subset subset, all_nodes, opts = nil
      topographic_sort(all_nodes, opts) & subset
    end

  end # module

end # module

