module Laser
  module Analysis
    # This class models a scope in Ruby. It has a constant table,
    # a self pointer, and a parent pointer to the enclosing scope.
    # It also has a local variable table.
    class Scope
      class ScopeLookupFailure < Error
        attr_accessor :scope, :query
        def initialize(scope, query)
          @scope, @query = scope, query
          super("Scope does not contain #{query.inspect}", nil, MAJOR_ERROR)
        end
      end

      # lexical_target = cref in YARV terms
      attr_accessor :constants, :parent, :locals, :method, :lexical_target
      def initialize(parent, self_ptr, constants={}, locals={})
        unless respond_to?(:lookup_local)
          raise NotImplementedError.new(
              'must create OpenScope or ClosedScope. Not just Scope.')
        end
        @parent, @constants, @locals = parent, constants, locals
        @locals['self'] = Bindings::LocalVariableBinding.new('self', self_ptr)
        if self_ptr && Bindings::Base === self_ptr
          self_ptr.self_owner = self
        end
        @lexical_target = self_ptr
        @method = nil
      end
      
      def initialize_copy(other)
        @locals = other.locals.dup
        @constants = other.constants.dup
      end
      
      def self_ptr
        @locals['self'].value
      end
      
      def self_ptr=(other)
        @locals['self'] = Bindings::LocalVariableBinding.new('self', other)
      end
      
      def add_binding!(new_binding)
        case new_binding.name[0,1]
        when /[A-Z]/
          constants[new_binding.name] = new_binding
        else
          locals[new_binding.name] = new_binding
        end
      end
      
      def path
        self_ptr.path
      end

      def lookup_or_create_local(var_name)
        lookup_local(var_name)
      rescue ScopeLookupFailure
        binding = Bindings::LocalVariableBinding.new(var_name, nil)
        add_binding!(binding)
        binding
      end

      # Proper variable lookup. The old ones were hacks.
      def lookup(str)
        if str[0,2] == '::'
          Scope::GlobalScope.lookup(str[2..-1])
        elsif str.include?('::')
          parts = str.split('::')
          final_scope = parts[0..-2].inject(self) { |scope, part| scope.lookup(part).scope }
          final_scope.lookup(parts.last)
        elsif str =~ /^\$/ then lookup_global(str)
        elsif str =~ /^@/ then lookup_ivar(str)
        elsif str =~ /^@@/ then lookup_cvar(str)
        else lookup_local(str)
        end
      end

      # Looks up a global binding. Defers to the global scope and creates on-demand.
      def lookup_global(str)
        Scope::GlobalScope.locals[str] ||=
            Bindings::GlobalVariableBinding.new(str, nil)
      end
      
      # Looks up an instance variable binding. Defers to the current value of self's
      # class, 
      def lookup_ivar(str)
        unless (result = self_ptr.klass.instance_variables[str])
          result = Bindings::InstanceVariableBinding.new(str, LaserObject.new)
          self_ptr.klass.add_instance_variable!(result)
        end
        result
      end
      
      # Does this scope see the given variable name?
      def sees_var?(var)
        lookup(var) rescue false
      end
    end
    
    class OpenScope < Scope
      def lookup_local(str)
        if locals[str]
        then locals[str]
        elsif parent then parent.lookup_local(str)
        else raise ScopeLookupFailure.new(self, str)
        end
      end
    end
    
    class ClosedScope < Scope
      def lookup_local(str)
        locals[str] or raise ScopeLookupFailure.new(self, str)
      end
    end
  end
end
