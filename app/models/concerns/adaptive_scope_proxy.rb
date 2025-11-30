module AdaptiveScopeProxy
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
      # NOTE: Arrayのインスタンスからklassを取るのはやりたくないのでここでキャプチャしておく
      klass = self
      define_linked_scope(
        scope_name,
        apply_loaded: ->(relation, _args, _blk) {
          records = relation.to_a
          klass.public_send(filter, records)
        }
      )
    end

    private

    def ensure_scope_linkable!(scope_name)
      raise ArgumentError, "Scope #{scope_name} is not defined" unless respond_to?(scope_name)
      yield(self) if block_given?
    end

    def define_linked_scope(scope_name, apply_loaded:)
      adaptive_scope_proxy_mutex.synchronize do
        array_module = (@array_module ||= Module.new)

        array_module.module_eval do
          define_method(scope_name) do |*args, &blk|
            apply_loaded.call(self, args, blk).extend(array_module)
          end
        end

        generated_relation_methods.module_eval do
          original = :"_adaptive_scope_proxy_original_#{scope_name}"
          unless method_defined?(scope_name)
            raise ArgumentError, "Scope #{scope_name} must be defined as a relation method (named scope)"
          end
          # もともと scope が Relation にも定義されているはずなので alias しておく
          unless method_defined?(original)
            alias_method original, scope_name
          end
          define_method(scope_name) do |*args, &blk|
            if respond_to?(:proxy_association) && loaded?
              apply_loaded.call(self, args, blk).extend(array_module)
            else
              public_send(original, *args, &blk)
            end
          end
        end
      end
    end

    def adaptive_scope_proxy_mutex
      @adaptive_scope_proxy_mutex ||= Mutex.new
    end
  end
end
