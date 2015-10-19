RSpec.shared_context "application mock helper", app_mock: true do
  let(:namespace) do
    Module.new do
    end
  end

  def module_for(name, &block)
    namespace_for(Module, name, &block)
  end

  def class_for(name, &block)
    namespace_for(Class, name, &block)
  end

  def namespace_for(type, name, &block)
    ns = namespace
    b = block

    klass = type.new do
      define_singleton_method :parents do
        [ns, 0]
      end

      class_exec(&b)
    end

    if name
      names = name.is_a?(Array) ? name : [name]

      last = names.pop

      if names.length > 0
        container = names.inject(namespace) do |m, name|
          begin
            m.const_get(name)
          rescue NameError
            m.const_set(name, Module.new)
          end
        end
      else
        container = namespace
      end

      begin
        container.const_get(last)
      rescue NameError
        container.const_set(last, klass)
      end
    end

    klass
  end
end
