require 'spec_helper'

describe Quiver::Model do
  subject(:test_model_klass) do
    Class.new do
      include Quiver::Model

      attribute :guid, Extant::Coercers::Uuid
      attribute :no_coercion
      attribute :some_foreign_id, Integer
      attribute :an_description,  String
      attribute :an_boolean,      Boolean

      validate :guid, presence: true, except: [:create]
#       validate :some_foreign_id, with: -> (attr) {
#         # do something here
#       }
    end
  end

  describe '#with' do
    let(:obj) do
      test_model_klass.new({an_boolean: true, an_description: 'waka waka'})
    end

    let(:new_obj) do
      obj.with({no_coercion: 'hahaha', an_description: 'not today'}, {user: 'johnny'})
    end

    it 'returns a new object with the new attributes' do
      expect(obj.object_id).to_not eq(new_obj.object_id)
      expect(new_obj).to have_attributes(
        an_boolean: true,
        no_coercion: 'hahaha',
        an_description: 'not today'
      )
    end

    it 'keep a reference to the objects original attributes' do
      expect(new_obj.original_attributes).to eq(
        guid: obj.guid,
        no_coercion: obj.no_coercion,
        some_foreign_id: obj.some_foreign_id,
        an_description: obj.an_description,
        an_boolean: obj.an_boolean
      )

      newer_obj = new_obj.with(an_boolean: true, no_coercion: false)

      expect(newer_obj.original_attributes).to eq(
        guid: obj.guid,
        no_coercion: obj.no_coercion,
        some_foreign_id: obj.some_foreign_id,
        an_description: obj.an_description,
        an_boolean: obj.an_boolean
      )
    end

    it 'has metadata' do
      expect(new_obj.with_metadata).to eq({user: 'johnny'})
    end
  end

  describe 'dirty?' do
    let(:foreign_id) { SecureRandom.uuid }
    let(:guid) { SecureRandom.uuid }
    let(:description) { 'This is some description action' }
    let(:model) { test_model_klass.new(some_foreign_id: foreign_id, guid: guid, an_description: description) }

    it 'returns false when nothing has changed' do
      # ExtantAttributeOverrides considers the model to be dirty unless it is
      # persisted, so "persist" it!
      model.persisted_by!(:memory)
      expect(model.dirty?).to eq(false)
    end

    context 'when something has changed' do
      before do
        model.an_description = 'This is a different description'
      end

      it 'returns true when something has changed without checking an attribute' do
        expect(model.dirty?).to eq(true)
      end

      it 'returns true when the specific attribute is checked' do
        expect(model.dirty?(:an_description)).to eq(true)
      end

      it 'returns false when a different attribute is checked that has not changed' do
        # ExtantAttributeOverrides considers the model to be dirty unless it is
        # persisted, so "persist" it!
        model.persisted_by!(:memory)
        expect(model.dirty?(:guid)).to eq(false)
      end
    end
  end

  describe 'attribute' do
    context 'definitions' do
      it 'create readers/writers' do
        model = test_model_klass.new
        expect(model).to respond_to(:guid)
        expect(model).to respond_to(:guid=)
        expect(model).to respond_to(:some_foreign_id)
        expect(model).to respond_to(:some_foreign_id=)
        expect(model).to respond_to(:an_description)
        expect(model).to respond_to(:an_description=)
      end

      it 'create working writers' do
        model = test_model_klass.new
        guid = SecureRandom.uuid

        expect do
          model.guid = guid
        end.to change(model, :guid).from(nil).to(guid)
      end
    end

    context 'coercions' do
      context 'when no coercion' do
        it 'still shows success' do
          model = test_model_klass.new(no_coercion: SecureRandom.uuid)
          expect(model.coerced?(:no_coercion)).to be_truthy
        end
      end

      context 'for guid' do
        it 'show success if guid is guid' do
          model = test_model_klass.new(guid: SecureRandom.uuid)
          expect(model.coerced?(:guid)).to be_truthy
        end

        it 'show success if guid is not present' do
          model = test_model_klass.new
          expect(model.coerced?(:guid)).to be_truthy
        end

        it 'show failure if guid is not guid' do
          model = test_model_klass.new(guid: 'foo-bar')
          expect(model.guid).to eq(nil)
          expect(model.coerced?(:guid)).to be_falsey
        end
      end

      context 'when not present or false' do
        it 'show success if an_description is not present' do
          model = test_model_klass.new
          expect(model.coerced?(:an_description)).to be_truthy
        end

        it 'show success if an_boolean is false' do
          model = test_model_klass.new(an_boolean: false)
          expect(model.coerced?(:an_boolean)).to be_truthy
        end
      end

      context 'for all attributes' do
        it 'shows failure if any one attribute was not coerced' do
          model = test_model_klass.new(guid: 'foo-bar')
          expect(model.coerced_all?).to be_falsey
        end
      end
    end

    context 'validation' do
      context 'tags' do
        it 'complains about missing guid if no tags are passed' do
          model = test_model_klass.new
          expect(model.validate.success?).to be_falsey
        end

        it 'does not run the guid validation if create tag is passed' do
          model = test_model_klass.new

          expect(model.validate(tags: [:create]).success?).to be_truthy
        end
      end

      context 'of coercions' do
        it 'complains that a coercion failed when validating' do
          model = test_model_klass.new(guid: 'foo-bar')
          result = model.validate

          expect(result.success?).to be_falsey
          expect(result.errors.second.subject).to eq(:guid)
          expect(result.errors.second.type).to eq('could_not_be_coerced_to_expected_type.uuid')
        end

        it 'complains that a coercion to integer failed when validating' do
          model = test_model_klass.new(some_foreign_id: 'foo-bar')
          result = model.validate

          expect(result.success?).to be_falsey

          error = result.errors.find { |e| e.subject == :some_foreign_id }
          expect(error.type).to eq('could_not_be_coerced_to_expected_type.integer')
        end
      end

      context 'of precense' do
        it 'must be present' do
          model = test_model_klass.new
          result = model.validate

          expect(result.success?).to be_falsey

          error = result.errors.find { |e| e.subject == :guid }
          expect(error.type).to eq('should_be_present')
        end
      end
    end
  end
end
