module Quiver
  module Mapper
    class SimpleQueryBuilder
      def initialize(mapper)
        self.mapper = mapper

        self._filter = {}
        self._sort = {}
        self._paginate = {}
      end

      def to_result
        filter_errors = _filter.reduce(Quiver::ErrorCollection.new) do |errors, (k, v)|
          if v
            errors + v.errors.each_with_object(Quiver::ErrorCollection.new) do |error, collection|
              collection << Quiver::Action::FilterError.new("#{k}: #{error.detail}")
            end
          else
            errors
          end
        end

        if filter_errors.any?
          return Quiver::Mapper::MapperResult.new([], filter_errors)
        end

        mapper.send(:query,
          filter: mapper.class.send(:default_filter).merge(_filter),
          sort: _sort,
          page: _paginate
        )
      end

      def filter(params)
        self._filter = params.to_h
        self
      end

      def sort(params)
        params ||= ''
        self._sort = params.split(',').map do |k|
          asc = k[0] != '-'
          k = k[1..-1] if !asc

          [k, asc]
        end.reject do |(k, _)|
          !allowed_sorts.include?(k.to_sym)
        end
        self
      end

      def paginate(params)
        self._paginate = params.to_h.slice('limit', 'offset')
        self
      end

      private

      attr_accessor :mapper, :adapter, :_filter, :_sort, :_paginate

      def allowed_filters
        mapper.class.send(:filters)
      end

      def allowed_sorts
        mapper.class.send(:sorts)
      end
    end
  end
end
