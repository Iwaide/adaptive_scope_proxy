module ScopeLinkerExtension
  # usage:
  #
  # class User < ApplicationRecord
  #   has_many :projects,
  #     &ScopeLinkerExtension.build_has_many_extension(
  #       predicates: {
  #         active:   :active?,
  #         archived: :archived?
  #       },
  #       filters: {
  #         latest_by_user:     :latest_by_user_filter,
  #         with_active_labels: :with_active_labels_filter
  #       }
  #     )
  # end
  #
  # class Project < ApplicationRecord
  #   scope :active,           -> { where(archived_at: nil) }
  #   scope :archived,         -> { where.not(archived_at: nil) }
  #   scope :latest_by_user,   -> { ... }  # DB版(ROW_NUMBERなど)
  #   scope :with_active_labels, -> { ... }
  #
  #   def active?;   archived_at.nil?; end
  #   def archived?; !active?; end
  #
  #   def self.latest_by_user_filter(records); ...; end
  #   def self.with_active_labels_filter(records); ...; end
  # end
  #
  def self.build_has_many_extension(predicates: {}, filters: {})
    # keys を symbol にそろえておく
    predicates = predicates.transform_keys(&:to_sym)
    filters    = filters.transform_keys(&:to_sym)

    proc do
      # self は has_many の extension module
      # Array 用の拡張は association とは別 module にする
      array_ext_mod = Module.new

      preds = predicates.dup.freeze
      fltrs = filters.dup.freeze

      #
      # Array 用: ここに「Ruby サイドでチェーンする」ためのメソッドを定義
      #
      (preds.keys + fltrs.keys).uniq.each do |scope_name|
        array_ext_mod.define_method(scope_name) do |*args, &blk|
          klass = instance_variable_get(:@_linked_model_class)

          filtered =
            if preds.key?(scope_name)
              predicate = preds.fetch(scope_name)
              select { |rec| rec.public_send(predicate, *args) }
            else
              filter = fltrs.fetch(scope_name)
              klass.public_send(filter, self)
            end
          filtered.tap do |arr|
            arr.extend(array_ext_mod)
            arr.instance_variable_set(:@_linked_model_class, klass)
          end
        end
      end

      #
      # Association(CollectionProxy) 用: AR の scope を override する
      #
      preds.each do |scope_name, predicate|
        define_method(scope_name) do |*args, &blk|
          klass = proxy_association.klass

          # モデル側に scope / predicate があるか一応チェック
          unless klass.respond_to?(scope_name)
            raise ArgumentError, "Scope #{scope_name} is not defined on #{klass.name}"
          end

          unless klass.instance_methods.include?(predicate)
            raise ArgumentError, "#{klass.name}##{predicate} is not defined"
          end

          # 未 loaded → 普通の AR 的挙動（DB スコープ）に任せる
          unless loaded?
            return super(*args, &blk)
          end

          # loaded → Ruby 側で predicate? でフィルタ（N+1 出さない）
          records  = to_a
          records.select { |rec| rec.public_send(predicate, *args) }.tap do |arr|
            arr.extend(array_ext_mod)
            arr.instance_variable_set(:@_linked_model_class, klass)
          end
        end
      end

      fltrs.each do |scope_name, filter|
        define_method(scope_name) do |*args, &blk|
          klass = proxy_association.klass

          unless klass.respond_to?(scope_name)
            raise ArgumentError, "Scope #{scope_name} is not defined on #{klass.name}"
          end

          unless klass.respond_to?(filter)
            raise ArgumentError, "#{klass.name}.#{filter} is not defined"
          end

          # 未 loaded → 普通に DB 版 scope に任せる
          unless loaded?
            return super(*args, &blk)
          end

          # loaded → class メソッド filter(records) で Ruby 集約
          records  = to_a
          klass.public_send(filter, records).tap do |arr|
            arr.extend(array_ext_mod)
            arr.instance_variable_set(:@_linked_model_class, klass)
          end
        end
      end
    end
  end
end
