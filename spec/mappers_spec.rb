require 'spec_helper'

describe Quiver::Mappers do
  [:active_record, :memory].each do |adapter_type|
    context "with #{adapter_type}" do
      before do
        Pwny::Application.default_adapter_type = adapter_type
      end

      let(:mapper) { Pwny::Mappers::DragonMapper.new }

      let(:dragon_one) do
        Pwny::Models::ClassicDragon.new(
          name: 'Nerroth Bringer of Death',
          color: 'green',
          size: 15600,
          gold_count: 519857,
          piles_of_bones: 1 # it's a really big pile
        )
      end

      let(:dragon_two) do
        Pwny::Models::ClassicDragon.new(
          name: 'Snapper The Hell Beast',
          color: 'red',
          size: 23780,
          gold_count: 3234,
          piles_of_bones: 2
        )
      end

      it 'saves the changes if nothing was raised' do
        expect do
          Pwny::Mappers.transaction do
            mapper.save(dragon_one)
            mapper.save(dragon_two)
          end
        end.to change { mapper.count.object }.by(2)
      end

      it 'it rolls back to previous state if exception raised within transaction' do
        expect do
          expect do
            Pwny::Mappers.transaction do
              mapper.save(dragon_one)
              mapper.save(dragon_two)

              raise "Hell hath no fury like a dragon!"
            end
          end.to raise_error("Hell hath no fury like a dragon!")
        end.to change { mapper.count.object }.by(0)
      end
    end
  end
end
