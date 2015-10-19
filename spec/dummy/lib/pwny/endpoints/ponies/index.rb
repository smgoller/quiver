module Pwny::Endpoints
  module Ponies
    class Index
      include Quiver::Action

      serializer Pwny::Serializers::PonySerializer

      extra_logging do
        { test: 'an extra field!' }
      end

      params do
        param :filter do
          param :color, type: FilterValue.with(String, :equalities, :inclusions)
          param :mane_length, type: FilterValue.with_all(Integer)
        end

        param :sort, type: String

        param :page do
          param :limit, type: Integer
          param :offset, type: Integer
        end
      end

      def action
        Pwny::Mappers::PonyMapper.new.filter(params['filter']).sort(params['sort']).paginate(params['page']).to_result
      end
    end
  end
end
