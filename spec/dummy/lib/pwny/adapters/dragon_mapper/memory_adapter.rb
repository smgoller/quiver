module Pwny::Adapters
  module DragonMapper
    class MemoryAdapter
      include Quiver::Adapter
      include Quiver::Adapter::MemoryHelpers

      primary_key_name :id

      private

      # def hydrate(attributes, _)
      #   object = {
      #     :classic_dragon => Pwny::Models::ClassicDragon,
      #     :modern_dragon => Pwny::Models::ModernDragon
      #   }[attributes.delete(:kind)].new

      #   attributes.each do |k, v|
      #     object.send(:"#{k}=", v) if object.respond_to?(:"#{k}=", true)
      #   end

      #   object.persisted_by!(adapter_type)
      #   object
      # end
    end
  end
end
