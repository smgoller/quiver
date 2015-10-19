module Quiver
  module Action
    class PaginationLinkBuilder
      def initialize(request_path_with_query, offset, limit, total_count)
        self.request_path_with_query = request_path_with_query
        self.offset = offset
        self.limit = limit
        self.total_count = total_count
      end

      def pagination_links
        links = {}
        links[:self] = request_path_with_query
        links[:last] = build_link(last_page)

        links[:next] = build_link(next_page) if next_page
        links[:prev] = build_link(previous_page) if previous_page

        links
      end

      private

      attr_accessor :request_path_with_query, :offset, :limit, :total_count

      def build_link(offset)
        uri = parsed_uri
        query_params = Rack::Utils.parse_nested_query(uri.query)
        query_params['page'] ||= {}
        query_params['page']['limit'] = limit
        query_params['page']['offset'] = offset
        uri.query = Rack::Utils.build_nested_query(query_params)
        uri.to_s
      end

      def parsed_uri
        URI.parse(request_path_with_query)
      end

      def next_page
        if limit != -1 && total_count > offset + limit
          offset + limit
        end
      end

      def previous_page
        if offset > 0
          if limit == -1
            0
          else
            [offset - limit, 0].max
          end
        end
      end

      def last_page
        if limit == -1
          0
        else
          # rounds total_count down to the offset that
          # represents the last page of the resources
          (total_count / limit) * limit
        end
      end
    end
  end
end
