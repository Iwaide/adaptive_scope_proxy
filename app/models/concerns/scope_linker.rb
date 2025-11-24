module ScopeLinker
  extend ActiveSupport::Concern

  class_methods do
    def link_scope_predicate(scope_name, predicate: "#{scope_name}?")
      raise ArgumentError, "Scope #{scope_name} is not defined" unless respond_to?(scope_name)
      raise ArgumentError, "Predicate method #{predicate} is not defined" unless instance_methods.include?(predicate.to_sym)
      singleton_class.define_method("linked_#{scope_name}") do |*args, &blk|
        scoped_records = self.public_send(scope_name, *args, &blk)
      end
      # Relation 用のモジュールを作成。Model.all で返る relation をこのモジュールで拡張する。
      relation_module = Module.new do
        define_method("linked_#{scope_name}") do |*args, &blk|
          # self は ActiveRecord::Relation のインスタンス、klass はモデルクラス
          model_scope = klass.public_send(scope_name, *args, &blk)

          # relation がロード済みなら Ruby 側で predicate を実行して配列を返す（既存コメントの方針）
          if loaded?
            unless klass.instance_methods.include?(predicate.to_sym)
              raise ArgumentError, "Predicate method #{predicate} is not defined on #{klass}"
            end
            to_a.select { |rec| rec.public_send(predicate, *args) }
          else
            public_send(scope_name, *args, &blk)
          end
        end
      end

      # Model.all が返す relation を常に relation_module で拡張するようにする
      singleton_class.class_eval do
        define_method(:all) do
          super().extending(relation_module)
        end
      end
    end
  end
end
