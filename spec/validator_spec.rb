require 'spec_helper'

describe Quiver::Validator do
  let(:validator) { Quiver::Validator.new(validation_definitions) }

  describe 'pre-defined convenience validators' do
    let(:validation_definitions) do
      [
        {
          attr_or_proc: :foo,
          options: {
            presence: 'option_value'
          }
        }
      ]
    end

    it 'calls out to Quiver::Validators::Presence' do
      object = OpenStruct.new(foo: 'something')
      expect(Quiver::Validators::Presence).to receive(:new)
        .with('something', 'option_value', :foo, nil, nil)
        .and_call_original

      validator.validate(object)
    end
  end

  describe 'proc-based' do
    context 'when returned object is not a Quiver::ErrorCollection' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: -> (obj) do
              false
            end,
            options: {}
          }
        ]
      end

      it 'raises an error' do
        object = OpenStruct.new

        expect do
          validator.validate(object)
        end.to raise_error(TypeError, /proc validators must return a Quiver::ErrorCollection/)
      end
    end

    context 'when no errors' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: -> (obj) do
              Quiver::ErrorCollection.new
            end,
            options: {}
          }
        ]
      end

      it 'works' do
        object = OpenStruct.new

        expect do
          validator.validate(object)
        end.to_not raise_error
      end
    end

    context 'when errors are returned' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: -> (obj) do
              collection = Quiver::ErrorCollection.new
              collection << Quiver::Error.new('subject', 'reason')
              collection
            end,
            options: {}
          }
        ]
      end

      it 'returns unsuccessful' do
        object = OpenStruct.new

        expect(validator.validate(object).success?).to be_falsey
      end
    end
  end

  describe 'conditionals' do
    context 'if' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: -> (obj) {
              obj.foo!
              Quiver::ErrorCollection.new
            },
            options: {
              if: -> (obj) {
                obj.blue?
              }
            }
          }
        ]
      end

      it 'runs when obj is blue' do
        obj = OpenStruct.new(blue?: true)
        expect(obj).to receive(:foo!)
        validator.validate(obj)
      end

      it 'does not run if object is not blue' do
        obj = OpenStruct.new(blue?: false)
        expect(obj).to_not receive(:foo!)
        validator.validate(obj)
      end
    end

    context 'unless' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: -> (obj) {
              obj.foo!
              Quiver::ErrorCollection.new
            },
            options: {
              unless: -> (obj) {
                obj.blue?
              }
            }
          }
        ]
      end

      it 'does not run when obj is blue' do
        obj = OpenStruct.new(blue?: true)
        expect(obj).to_not receive(:foo!)
        validator.validate(obj)
      end

      it 'runs when object is not blue' do
        obj = OpenStruct.new(blue?: false)
        expect(obj).to receive(:foo!)
        validator.validate(obj)
      end
    end
  end

  describe 'tags' do
    context 'with except' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: :foo,
            options: {
              presence: 'option_value',
              except: [:bar]
            }
          }
        ]
      end

      it 'runs when bar is not passed' do
        object = OpenStruct.new(foo: 'something')
        expect(Quiver::Validators::Presence).to receive(:new).and_call_original

        validator.validate(object)
      end

      it 'does not run when bar is passed' do
        object = OpenStruct.new(foo: 'something')
        expect(Quiver::Validators::Presence).to_not receive(:new)

        validator.validate(object, tags: [:bar])
      end
    end

    context 'with only' do
      let(:validation_definitions) do
        [
          {
            attr_or_proc: :foo,
            options: {
              presence: 'option_value',
              only: [:bar]
            }
          }
        ]
      end

      it 'does not run when bar is not passed' do
        object = OpenStruct.new(foo: 'something')
        expect(Quiver::Validators::Presence).to_not receive(:new)

        validator.validate(object)
      end

      it 'runs when bar is passed' do
        object = OpenStruct.new(foo: 'something')
        expect(Quiver::Validators::Presence).to receive(:new).and_call_original

        validator.validate(object, tags: [:bar])
      end
    end
  end
end
