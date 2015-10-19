require 'spec_helper'

describe Quiver::Adapter::Memory, app_mock: true do
  let!(:application) do
    class_for(:Application) do
      def self.default_adapter_type
        :memory
      end

      def self.memory_adapter_store
        @memory_adapter_store ||= Quiver::Adapter::MemoryAdapterStore.new
      end
    end
  end

  let!(:adapter_klass) do
    class_for([:Adapter, :WidgetMapper, :MemoryAdapter]) do
      include Quiver::Adapter::Memory

      primary_key_name :id

      def mapper_name
        'widget_mapper'
      end
    end
  end

  context '#find' do
    before do
      application.memory_adapter_store.get('widget_mapper')[1] = {
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      }
    end

    it 'returns a hash representing the attributes of the resource' do
      expect(adapter_klass.new.find(1)).to eq(
        Quiver::Adapter::AdapterResult.new({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        })
      )
    end
  end

  context '#query' do
    before do
      application.memory_adapter_store.get('widget_mapper')[1] = {
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      }
    end

    it 'returns a hash representing the attributes of the resource' do
      expect(adapter_klass.new.query({})).to eq(
        Quiver::Adapter::AdapterResult.new([
          {
            id: 1,
            name: 'Perfectly Generic Widget',
            color: 'Blue'
          }
        ])
      )
    end
  end

  context '#create' do
    it 'creates an entry in the memory store' do
      expect(
        adapter_klass.new.create({
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        }, :transaction_double)
      ).to eq(
        Quiver::Adapter::AdapterResult.new({
          id: 1,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        })
      )

      expect(application.memory_adapter_store.get('widget_mapper')[1]).to eq(
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      )
    end
  end

  context '#update' do
    before do
      application.memory_adapter_store.get('widget_mapper')[1] = {
        id: 1,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      }
    end

    it 'updates an entry in the memory store' do
      expect(
        adapter_klass.new.update({
          id: 1,
          name: 'No Longer Perfectly Generic Widget',
          color: 'Yellow'
        }, :transaction_double)
      ).to eq(
        Quiver::Adapter::AdapterResult.new({
          id: 1,
          name: 'No Longer Perfectly Generic Widget',
          color: 'Yellow'
        })
      )

      expect(application.memory_adapter_store.get('widget_mapper')[1]).to eq({
        id: 1,
        name: 'No Longer Perfectly Generic Widget',
        color: 'Yellow'
      })
    end
  end

  context 'backwards compatability' do
    it 'is aliased as MemoryHelper' do
      expect(Quiver::Adapter::MemoryHelpers).to eq(described_class)
    end
  end
end
