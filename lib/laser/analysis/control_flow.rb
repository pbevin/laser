require 'laser/BasicBlock'
require 'laser/analysis/control_flow/basic_block'
require 'laser/analysis/control_flow/cfg_instruction'
require 'laser/analysis/control_flow/unused_variables'
require 'laser/analysis/control_flow/unreachability_analysis'
require 'laser/analysis/control_flow/constant_propagation'
require 'laser/analysis/control_flow/simulation'
require 'laser/analysis/control_flow/lifetime_analysis'
require 'laser/analysis/control_flow/static_single_assignment'
require 'laser/analysis/control_flow/alias_analysis'
require 'laser/analysis/control_flow/yield_properties'
require 'laser/analysis/control_flow/method_call_search'
require 'laser/analysis/control_flow/alias_analysis'
require 'laser/analysis/control_flow/raise_properties'
require 'laser/analysis/control_flow/guaranteed_super_detection'
require 'laser/analysis/control_flow/cfg_builder'
require 'laser/analysis/control_flow/control_flow_graph'

module Laser
  module Analysis
    module ControlFlow
      def self.perform_cfg_analysis(tree, text, opts={})
        graph = GraphBuilder.new(tree).build
        graph.analyze(opts)
        graph
      end
    end
  end
end
