module Quiver
  module Adapter
    module Memory
      module UuidPrimaryKey
        def self.included(k)
          k.send(:extend, ClassMethods)
        end

        module ClassMethods
          def next_pk
            @pk_series ||= []

            new_pk = SecureRandom.uuid
            while @pk_series.include?(new_pk)
              new_pk = SecureRandom.uuid
            end

            @pk_series << new_pk
            new_pk
          end
        end
      end
    end
  end
end
