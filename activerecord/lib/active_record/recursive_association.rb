  # frozen_string_literal: true

module ActiveRecord
  module RecursiveAssociation
    extend ActiveSupport::Concern

    module AssociationBuilderExtension #:nodoc:
      # What we are doing here is defining a setter that will work for both the attribute and associations.
      # Since the column name can be identical to the association name we need to check if the value
      # should use the association writer or the attribute writer.
      def self.build(model, reflection)
        reflection_name = reflection.name.to_s
        # Only generate this method if the reflection has a foreign_key that's the same as it's name.
        return if reflection.options[:foreign_key] != reflection_name

        mixin = model.generated_association_methods
        ActiveModel::AttributeMethods::AttrNames.define_attribute_accessor_method(
          mixin, reflection_name, writer: true
        ) do |temp_method_name, attr_name_expr|
          mixin.class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{temp_method_name}(value)
              if (value.is_a?(Class) ? value : value.class) < ActiveRecord::Base
                association(:#{reflection_name}).writer(value)
              else
                name = #{attr_name_expr}
                _write_attribute(name, value)
              end
            end
          RUBY
        end
      end

      def self.valid_options
        []
      end
    end

    included do
      Associations::Builder::Association.extensions << AssociationBuilderExtension
    end
  end
end
