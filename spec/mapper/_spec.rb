require 'spec_helper'

describe Quiver::Mapper, app_mock: true do
  let!(:mappers_module) do
    module_for([:Mappers]) do
      def self.transaction(&block)
        block.call(:transaction_double)
      end
    end
  end

  let!(:mapper_klass) do
    mk = model_klass

    class_for([:Mappers, :WidgetMapper]) do
      include Quiver::Mapper

      maps mk

      def self.name
        'WidgetMapper'
      end
    end
  end

  let!(:model_klass) do
    class_for([:Models, :Widget]) do
      attr_accessor :deleted_at

      def initialize(persisted)
        @persisted = persisted
      end

      def id=(val)
      end

      def attributes
        {
          id: pk,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: deleted_at
        }
      end

      def pk
        @persisted ? 1 : nil
      end

      def validate(*args)
        Quiver::ErrorCollection.new
      end

      def persisted?
        @persisted
      end

      def persisted_by
        @persisted ? [:memory] : []
      end

      def persisted_by!(val)
        @persisted = true
      end
    end
  end

  let!(:adapter_klass) do
    class_for([:Adapters, :WidgetMapper, :MemoryAdapter]) do
      def primary_key_name
        :id
      end
    end
  end

  let!(:application) do
    class_for(:Application) do
      def self.default_adapter_type
        :memory
      end
    end
  end

  describe '#save' do
    context 'with unpersisted model' do
      it 'calls create on the adapter with the appropriate attributes' do
        model = model_klass.new(false)
        created_model = model_klass.new(false)

        adapter = adapter_klass.new
        allow(adapter_klass).to receive(:new).and_return(adapter)
        expect(adapter).to receive(:create).with({
          id: nil,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: nil
        }, :transaction_double).and_return(
          Quiver::Adapter::AdapterResult.new({
            id: 1,
            name: 'Perfectly Generic Widget',
            color: 'Blue'
          })
        )

        allow(model_klass).to receive(:new).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        }).and_return(created_model)

        result = mapper_klass.new.save(model)

        expect(result.object).to eq(created_model)
        expect(result.object.persisted?).to eq(true)
      end
    end

    context 'with persisted model' do
      it 'calls create on the adapter with the appropriate attributes' do
        model = model_klass.new(true)
        # starts with persisted: false because it is a blank model that is
        # created within the mapper
        updated_model = model_klass.new(false)

        adapter = adapter_klass.new
        allow(adapter_klass).to receive(:new).and_return(adapter)
        expect(adapter).to receive(:update).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: nil
        }, :transaction_double).and_return(
          Quiver::Adapter::AdapterResult.new({
            id: 1,
            name: 'Perfectly Generic Widget',
            color: 'Blue'
          })
        )

        allow(model_klass).to receive(:new).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        }).and_return(updated_model)

        result = mapper_klass.new.save(model)

        expect(result.object).to eq(updated_model)
        expect(result.object.persisted?).to eq(true)
      end
    end
  end

  describe '#hard_delete' do
    it 'calls adapter#hard_delete with attributes, and returns empty result' do
      model = model_klass.new(true)

      adapter = adapter_klass.new
      allow(adapter_klass).to receive(:new).and_return(adapter)
      expect(adapter).to receive(:hard_delete).with({
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue',
        deleted_at: nil
      }, :transaction_double).and_return(
        Quiver::Adapter::AdapterResult.new({})
      )

      expect(model_klass).to_not receive(:new)
      result = mapper_klass.new.hard_delete(model)

      expect(result.success?).to eq(true)
    end
  end

  describe '#restore' do
    it 'calls adapter#update with attributes, and returns hydrated model' do
      model = model_klass.new(true)
      # starts with persisted: false because it is a blank model that is
      # created within the mapper
      undeleted_model = model_klass.new(false)

      adapter = adapter_klass.new
      allow(adapter_klass).to receive(:new).and_return(adapter)

      result = nil

      Timecop.freeze do
        expect(adapter).to receive(:update).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: nil
        }, :transaction_double).and_return(
          Quiver::Adapter::AdapterResult.new({
            id: 1,
            name: 'Perfectly Generic Widget',
            color: 'Blue',
            deleted_at: nil
          })
        )

        allow(model_klass).to receive(:new).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: nil
        }).and_return(undeleted_model)

        result = mapper_klass.new.restore(model)
      end

      expect(result.object).to eq(undeleted_model)
      expect(result.object.persisted?).to eq(true)
    end
  end

  describe '#soft_delete' do
    it 'calls adapter#update with attributes, and returns hydrated model' do
      model = model_klass.new(true)
      # starts with persisted: false because it is a blank model that is
      # created within the mapper
      deleted_model = model_klass.new(false)

      adapter = adapter_klass.new
      allow(adapter_klass).to receive(:new).and_return(adapter)

      result = nil

      Timecop.freeze do
        expect(adapter).to receive(:update).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: Time.now,
        }, :transaction_double).and_return(
          Quiver::Adapter::AdapterResult.new({
            id: 1,
            name: 'Perfectly Generic Widget',
            color: 'Blue',
            deleted_at: Time.now
          })
        )

        allow(model_klass).to receive(:new).with({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue',
          deleted_at: Time.now
        }).and_return(deleted_model)

        result = mapper_klass.new.soft_delete(model)
      end

      expect(result.object).to eq(deleted_model)
      expect(result.object.persisted?).to eq(true)
    end
  end

  describe '#find' do
    it 'calls adapter#find with primary key, and returns hydrated model' do
      adapter = adapter_klass.new
      allow(adapter_klass).to receive(:new).and_return(adapter)
      expect(adapter).to receive(:find).with(1).and_return(
        Quiver::Adapter::AdapterResult.new({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        })
      )

      found_model = model_klass.new(false)

      allow(model_klass).to receive(:new).with({
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      }).and_return(found_model)

      result = mapper_klass.new.find(1)

      expect(result.object).to eq(found_model)
    end
  end

  describe 'filter, sort and paginate' do
    it '#filter creates a query object and passes the appropriate information along' do
      mapper = mapper_klass.new
      query_object = double('query_object')
      expect(Quiver::Mapper::SimpleQueryBuilder).to receive(:new).with(mapper).and_return(query_object)
      expect(query_object).to receive(:filter).with({foo: {bar: :baz}})

      mapper.filter({foo: {bar: :baz}})
    end

    it '#sort creates a query object and passes the appropriate information along' do
      mapper = mapper_klass.new
      query_object = double('query_object')
      expect(Quiver::Mapper::SimpleQueryBuilder).to receive(:new).with(mapper).and_return(query_object)
      expect(query_object).to receive(:sort).with('+whatevs')

      mapper.sort('+whatevs')
    end

    it '#paginate creates a query object and passes the appropriate information along' do
      mapper = mapper_klass.new
      query_object = double('query_object')
      expect(Quiver::Mapper::SimpleQueryBuilder).to receive(:new).with(mapper).and_return(query_object)
      expect(query_object).to receive(:paginate).with({page: {limit: 1}})

      mapper.paginate({page: {limit: 1}})
    end
  end

  describe '#query' do
    it 'is a private method' do
      expect do
        mapper_klass.new.query
      end.to raise_error(NoMethodError, %r|private method|)
    end

    it 'takes a hash with potential keys :filter, :sort, and :paginate and passes them into the adapter' do
      fetched_model = model_klass.new(false)

      adapter = adapter_klass.new
      allow(adapter_klass).to receive(:new).and_return(adapter)
      expect(adapter).to receive(:query).with({
        filter: {foo: {bar: :baz}},
        page: {limit: 1, offset: 3}
      }).and_return(
        Quiver::Adapter::AdapterResult.new([{
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        }])
      )

      allow(model_klass).to receive(:new).with({
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      }).and_return(fetched_model)

      result = mapper_klass.new.send(:query, {
        filter: {foo: {bar: :baz}},
        page: {limit: 1, offset: 3}
      })

      expect(result.object).to eq([fetched_model])
      expect(result.object.first.persisted?).to eq(true)
    end
  end
end
