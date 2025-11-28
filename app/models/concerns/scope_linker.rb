module ScopeLinker
  extend ActiveSupport::Concern

  class_methods do
    def link_scope_predicate(scope_name, predicate: "#{scope_name}?")
      ensure_scope_linkable!(scope_name) do |klass|
        unless klass.instance_methods.include?(predicate.to_sym)
          raise ArgumentError, "Predicate method #{predicate} is not defined"
        end
      end

      define_linked_scope(
        scope_name,
        apply_loaded: ->(relation, args, _blk) {
          relation.select { |rec| rec.public_send(predicate, *args) }
        }
      )
    end

    def link_scope_filter(scope_name, filter: "#{scope_name}_filter")
      ensure_scope_linkable!(scope_name) do |klass|
        unless klass.respond_to?(filter)
          raise ArgumentError, "Filter method #{filter} is not defined"
        end
      end

      define_linked_scope(
        scope_name,
        apply_loaded: ->(relation, _args, _blk) {
          relation.klass.public_send(filter, relation.to_a)
        }
      )
    end

    private

    def ensure_scope_linkable!(scope_name)
      raise ArgumentError, "Scope #{scope_name} is not defined" unless respond_to?(scope_name)
      yield(self) if block_given?
    end

    def define_linked_scope(scope_name, apply_loaded:)
      array_module = (@array_module ||= Module.new)
      relation_module = (@relation_module ||= Module.new)

      singleton_class.define_method("linked_#{scope_name}") do |*args, &blk|
        public_send(scope_name, *args, &blk)
      end

      array_module.module_eval do
        define_method("linked_#{scope_name}") do |*args, &blk|
          apply_loaded.call(self, args, blk).extend(array_module)
        end
      end

      relation_module.module_eval do
        define_method("linked_#{scope_name}") do |*args, &blk|
          if loaded?
            apply_loaded.call(self, args, blk).extend(array_module)
          else
            public_send(scope_name, *args, &blk)
          end
        end
      end

      unless singleton_class.method_defined?(:_scope_linker_all_overridden)
        singleton_class.class_eval do
          define_method(:_scope_linker_all_overridden) { true }
          define_method(:all) do
            super().extending(@relation_module)
          end
        end
      end

      generated_relation_methods.module_eval do
        define_method("linked_#{scope_name}") do |*args, &blk|
          if loaded?
            apply_loaded.call(self, args, blk).extend(array_module)
          else
            public_send(scope_name, *args, &blk)
          end
        end
      end
    end
  end
end
