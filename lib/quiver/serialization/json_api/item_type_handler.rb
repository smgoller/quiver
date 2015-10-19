module Quiver::Serialization::JsonApi
  class NoIdError < StandardError
  end

  class ItemTypeHandler
    attr_accessor :type

    def initialize(type, config_block, no_id=false)

      self.attributes_storage = {}
      self.links = {}
      self.type = type

      instance_exec(&config_block)

      raise NoIdError, "no :id in handler for type #{type}" unless no_id || attributes_storage[:id]
    end

    def link(name, opts={})
      links[name] = opts
    end

    def attribute(name, opts={})
      attributes_storage[name] = opts
    end

    def attributes(*names)
      names.each do |name|
        attribute(name)
      end
    end

    def calculated_attribute(name, &block)
      attributes_storage[name] = {
        proc: block
      }
    end

    def serialize(item, opts={})
      context = opts[:context]

      serialized_links = links.each_with_object({}) do |(name, opts), h|
        h[name] = {}

        if href_proc = opts[:resource]
          h[name][:resource] = context.instance_exec(item, &href_proc)
        end

        if self_proc = opts[:self]
          h[name][:self] = context.instance_exec(item, &self_proc)
        end

        if value_proc = opts[:value]
          value = value_from_proc(value_proc, item)
          key = value.is_a?(Array) ? :ids : :id

          h[name][key] = value
        end

        if type = opts[:type]
          h[name][:type] = type
        end

        h[name].merge!(scope: context.instance_exec(item, &opts[:scope])) if opts[:scope]
      end

      serialized_attributes = attributes_storage.each_with_object({}) do |(name, opts), h|
        if proc = opts[:proc]
          h[name] = context.instance_exec(item, &proc)
        elsif attr_alias = opts[:alias]
          h[name] = item.send(attr_alias)
        else
          h[name] = item.send(name)
        end
      end

      if serialized_links.count > 0
        serialized_attributes.merge(links: serialized_links)
      else
        serialized_attributes
      end
    end

    private

    attr_accessor :attributes_storage, :links

    def value_from_proc(potential_proc, item)
      if potential_proc.respond_to?(:call)
        potential_proc.call(item)
      else
        potential_proc
      end
    end
  end
end
