require 'spec_helper'
require 'active_record'

describe Quiver::Adapter::ActiveRecord, app_mock: true do
  let!(:application) do
    class_for(:Application) do
      def self.using_active_record
        true
      end

      def self.default_adapter_type
        :active_record
      end
    end
  end

  let!(:adapter_klass) do
    class_for([:Adapter, :WidgetMapper, :ActiveRecord]) do
      include Quiver::Adapter::ActiveRecord

      primary_key_name :id
      define_record_class 'WidgetRecord', table: 'widgets'
      use_record_class 'WidgetRecord'
    end
  end

  let(:widget_record_klass) { adapter_klass.record_classes['WidgetRecord'] }

  context '#find' do
    let!(:widget1) {
      widget_record_klass.create({
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      })
    }

    it 'returns a hash representing the attributes of the resource' do
      expect(adapter_klass.new.find(widget1.id)).to eq(
        Quiver::Adapter::AdapterResult.new({
          id: widget1.id,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        })
      )
    end
  end

  context '#query' do
    let!(:widget1) {
      widget_record_klass.create({
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      })
    }

    it 'returns a hash representing the attributes of the resource' do
      expect(adapter_klass.new.query({})).to eq(
        Quiver::Adapter::AdapterResult.new([
          {
            id: widget1.id,
            name: 'Perfectly Generic Widget',
            color: 'Blue'
          }
        ])
      )
    end
  end

  context '#create' do
    it 'creates an entry in active record' do
      expect(
        adapter_klass.new.create({
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        }, :transaction_double)
      ).to eq(
        Quiver::Adapter::AdapterResult.new({
          id: widget_record_klass.last.id,
          name: 'Perfectly Generic Widget',
          color: 'Blue'
        })
      )

      expect(widget_record_klass.last.attributes.symbolize_keys).to eq({
        id: widget_record_klass.last.id,
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      })
    end
  end

  context '#update' do
    let!(:widget1) {
      widget_record_klass.create({
        name: 'Perfectly Generic Widget',
        color: 'Blue'
      })
    }

    it 'updates an entry in active record' do
      expect(
        adapter_klass.new.update({
          id: widget1.id,
          name: 'No Longer Perfectly Generic Widget',
          color: 'Yellow'
        }, :transaction_double)
      ).to eq(
        Quiver::Adapter::AdapterResult.new({
          id: widget1.id,
          name: 'No Longer Perfectly Generic Widget',
          color: 'Yellow'
        })
      )

      expect(widget1.reload.attributes.symbolize_keys).to eq({
        id: widget1.id,
        name: 'No Longer Perfectly Generic Widget',
        color: 'Yellow'
      })
    end
  end

  context 'backwards compatability' do
    it 'is aliased as ActiveRecordHelpers' do
      expect(Quiver::Adapter::ActiveRecordHelpers).to eq(described_class)
    end
  end
end
