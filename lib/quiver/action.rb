module Quiver
  module Action
    def self.included(host)
      host.send(:include, AbstractAction)
      host.send(:extend, ClassMethods)

      # prepend over Lotus's prepends
      host.send(:prepend, DurationTracking)
      host.send(:prepend, Logging)
    end

    module DurationTracking
      def call(params)
        start_duration_tracking
        super(params)
      ensure
        finish_duration_tracking
      end
    end

    module Logging
      def call(params)
        super(params)
      ensure
        if params == nil
          raise '#params is nil inside of a Quiver::Action. Something probably went wrong internally.'
        end

        logging_fields = default_logging_fields

        self.class.send(:extra_logging_blocks).reverse.each do |block|
          logging_fields.merge!(instance_exec(&block))
        end

        logger.info(logging_fields.merge(extra_logging_fields))
      end
    end

    module ClassMethods
      def extra_logging(&block)
        extra_logging_blocks << block
      end

      private

      def extra_logging_blocks
        @extra_logging_blocks ||= []
      end
    end

    def internal_call(params)
      self.params = params

      if params.raw[:terrible_hack].is_a?(JSON::ParserError)
        return serialize_with(errors: [Quiver::Action::InvalidRequestBodyError.new])
      end

      serialize_with(run_action)
    rescue Quiver::Error => e
      serialize_with(errors: [e])
    end

    private

    attr_accessor :duration_ms, :db_duration_ms, :duration_start_time, :params

    # for hooking in without prepend
    def run_action
      action
    end

    def start_duration_tracking
      self.duration_start_time = Time.now

      if defined?(ActiveRecord)
        ActiveRecord::LogSubscriber.reset_runtime
      end
    end

    def finish_duration_tracking
      if defined?(ActiveRecord) && ActiveRecord::Base.connected?
        self.db_duration_ms = ActiveRecord::LogSubscriber.reset_runtime
      else
        self.db_duration_ms = 0
      end

      self.duration_ms = (Time.now - duration_start_time) * 1000 - db_duration_ms
    end

    def extra_logging_fields
      {}
    end

    def default_logging_fields
      {
        method: params.env['REQUEST_METHOD'],
        path: request_path_with_query,
        controller: self.class.to_s.split('::').first.underscore,
        action: self.class.to_s.split('::').last.underscore,
        status: @_status || self.class::DEFAULT_RESPONSE_CODE,
        ip: request.ip,
        route: "#{self.class.to_s.split('::').first.underscore}##{self.class.to_s.split('::').last.underscore}",
        request_id: request_id,
        tags: [:request],
        duration: duration_ms.round(1),
        db: db_duration_ms.round(1) || 0,
        '@timestamp' => Time.now.utc,
        '@version' => '1'
      }
    end

    def route_helper
      RouteHelper.new(self.class.parents[-2]::Config::Router.new.send(:router))
    end

    def logger
      @logger ||= self.class.parents[-2]::Application.logger
    end

    def patch_serialize_with(data)
      if data[:patch_data]
        self.status = 200
        self.format = :json_api
        self.body = data[:patch_data].to_json
      else
        data[:patch_errors] = data[:patch_errors].map do |datum|
          datum.select { |k, _| k == :errors }
        end

        self.status = 400
        self.format = :json_api
        self.body = data[:patch_errors].to_json
      end
    end

    def serialize_with(data)
      if data.is_a?(Quiver::Result)
        mapper_result = data
        data = if data.success?
          {
            data: arrayify(data.object)
          }.tap do |h|
            h[:pagination_offset] = data.data[:pagination_offset] if data.data.key?(:pagination_offset)
            h[:pagination_limit] = data.data[:pagination_limit] if data.data.key?(:pagination_limit)
            h[:total_count] = data.data[:total_count] if data.data.key?(:total_count)
          end
        else
          {errors: data.errors}
        end
      end

      return patch_serialize_with(data) if data.keys.include?(:patch_data) || data.keys.include?(:patch_errors)

      errors = data[:errors] || []

      if errors.count > 0
        self.status = errors.first.status
      else
        if data.keys.count == 0
          self.status = 204
        else
          if mapper_result && data[:data].count == 1 && mapper_result.data[:adapter_op] == :create
            self.status = 201
          else
            self.status = 200
          end
        end
      end

      self.format = :json_api
      hash_body = self.class.serializer.new({collections: data}).serialize(context: self)

      hash_body.merge!(
        links: PaginationLinkBuilder.new(
          request_path_with_query, data[:pagination_offset], data[:pagination_limit], data[:total_count]
        ).pagination_links
      ) if data.key?(:pagination_offset)

      meta = {}

      if data.key?(:pagination_offset)
        meta[:page] ||= {}

        meta[:page][:offset] = data[:pagination_offset] if data.key?(:pagination_offset)
        meta[:page][:limit] = data[:pagination_limit] if data.key?(:pagination_limit) && data[:pagination_limit] != -1
        meta[:page][:total] = data[:total_count] if data.key?(:total_count)
      end

      hash_body.merge!(
        meta: meta
      )

      self.body = hash_body.to_json
    end

    def request_path
      @request_path ||= request.path || ''
    end

    def request_path_with_query
      @request_path_with_query ||= request.fullpath || ''
    end
  end
end

require 'quiver/action/filter_value'
require 'quiver/action/pagination_link_builder'
require 'quiver/action/invalid_request_body_error'
