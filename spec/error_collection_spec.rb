require 'spec_helper'

describe Quiver::ErrorCollection do
  it 'allows accessing the errors' do
    collection = Quiver::ErrorCollection.new
    collection << Quiver::Error.new(nil, nil)
    collection << Quiver::Error.new(nil, nil)

    expect(collection.errors.size).to eq(2)
  end

  context '+ Quiver::ErrorCollection' do
    it 'returns a merged collection' do
      collection1 = Quiver::ErrorCollection.new
      collection2 = Quiver::ErrorCollection.new

      collection1 << Quiver::Error.new(nil, nil)
      collection2 << Quiver::Error.new(nil, nil)

      collection3 = collection1 + collection2
      expect(collection3.errors.size).to eq(2)
    end
  end

  context '#success?' do
    it 'returns true when there are no errors' do
      collection = Quiver::ErrorCollection.new
      expect(collection.success?).to be_truthy
    end

    it 'returns false when there are errors' do
      collection = Quiver::ErrorCollection.new
      collection << Quiver::Error.new(nil, nil)

      expect(collection.success?).to be_falsey
    end
  end

  context 'argument validation' do
    context '.new' do
      it 'raises an ArgumentError if the initial array contains non-Quiver::Errors' do
        expect do
          Quiver::ErrorCollection.new([Quiver::Error.new(nil, nil), 2, 3])
        end.to raise_error(ArgumentError)
      end
    end

    context '#<<' do
      it 'raises an ArgumentError if the value is not a Quiver::Error' do
        collection = Quiver::ErrorCollection.new

        expect do
          collection << 2
        end.to raise_error(ArgumentError)
      end
    end

    context '#+' do
      it 'raises an ArgumentError if the rvalue is not a Quiver::ErrorCollection' do
        collection = Quiver::ErrorCollection.new

        expect do
          collection + 1
        end.to raise_error(ArgumentError)
      end
    end
  end
end
