require 'spec_helper'

describe 'Persistence' do
  describe 'mappers' do
    [:active_record, :memory].each do |adapter_type|
      context 'filtering' do
        context "when adapter ':#{adapter_type}' is used" do
          before do
            Pwny::Application.default_adapter_type = adapter_type
          end

          let(:mapper) { Pwny::Mappers::PonyMapper.new }

          let!(:purple_ponies) { FactoryGirl.create_list(:pony, 3, color: 'purple', mane_length: 3) }
          let!(:orange_ponies) { FactoryGirl.create_list(:pony, 4, color: 'orange', mane_length: 5) }
          let!(:brown_ponies) { FactoryGirl.create_list(:pony, 5, color: 'brown', mane_length: 7) }

          it 'supports long form equality ?filter[color][eq]=purple' do

            result = mapper.filter(
              'color' => Quiver::Action::FilterValue.with_all(String).new(
                {'eq' => 'purple'}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(3)
          end

          it 'supports negated equality ?filter[color][~eq]=purple' do
            result = mapper.filter(
              'color' => Quiver::Action::FilterValue.with_all(String).new(
                {'~eq' => 'purple'}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(9)
          end

          it %q|supports 'in' queries ?filter[color][in]=purple&filter[color][in]=orange| do
            result = mapper.filter(
              'color' => Quiver::Action::FilterValue.with_all(String).new(
                {'in' => ['purple', 'orange']}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(7)
          end

          it %q|supports negated 'in' queries ?filter[color][~in]=purple&filter[color][~in]=orange| do
            result = mapper.filter(
              'color' => Quiver::Action::FilterValue.with_all(String).new(
                {'~in' => ['purple', 'orange']}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(5)
          end

          it %q|supports 'lt' (less than) queries ?filter[mane_length][lt]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'lt' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(3)
          end

          it %q|supports negated 'lt' (not less than) queries ?filter[mane_length][~lt]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'~lt' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(9)
          end

          it %q|supports 'gt' (greater than) queries ?filter[mane_length][gt]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'gt' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(5)
          end

          it %q|supports negated 'gt' (not greater than) queries ?filter[mane_length][~gt]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'~gt' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(7)
          end

          it %q|supports 'gte' (greater than or equal) queries ?filter[mane_length][gte]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'gte' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(9)
          end

          it %q|supports negated 'gte' (not greater than or equal) queries ?filter[mane_length][~gte]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'~gte' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(3)
          end

          it %q|supports 'lte' (less than or equal) queries ?filter[mane_length][lte]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'lte' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(7)
          end

          it %q|supports negated 'lte' (not less than or equal) queries ?filter[mane_length][~lte]=4| do
            result = mapper.filter(
              'mane_length' => Quiver::Action::FilterValue.with_all(Integer).new(
                {'~lte' => 5}
              )
            ).to_result

            expect(result.success?).to eq(true)
            expect(result.object.count).to eq(5)
          end

          context 'presence filters' do
            let!(:nil_color_ponies) { FactoryGirl.create_list(:pony, 1, color: nil, mane_length: 7) }

            it %q|supports 'nil' (is nil) queries ?filter[color][nil]=true| do
              result = mapper.filter(
                'color' => Quiver::Action::FilterValue.with_all(Integer).new(
                  {'nil' => 'true'}
                )
              ).to_result

              expect(result.success?).to eq(true)
              expect(result.object.count).to eq(1)
            end
          end

          context 'custom filters' do
            it %q|supports custom 'near' (within one of) filter ?filter[mane_length][near]=4| do
              result = mapper.filter(
                'mane_length' => Quiver::Action::FilterValue.with(Integer, extras: [:near]).new(
                  {'near' => 4}
                )
              ).to_result

              expect(result.success?).to eq(true)
              expect(result.object.count).to eq(7)
            end
          end
        end
      end

      context "when adapter ':#{adapter_type}' is used" do
        before do
          Pwny::Application.default_adapter_type = adapter_type
        end

        let(:mapper_builder) { -> { Pwny::Mappers::PonyMapper.new(adapter_type) } }

        it 'can persist and find models' do
          daylight_twinkles = Pwny::Models::Pony.new(
            name: 'Daylight Twinkles',
            color: 'orange',
            mane_length: 25,
            unicorn: true,
            pegasus: false,
            unique_id: 1
          )

          result = mapper_builder.call.save(daylight_twinkles)
          expect(result.success?).to eq(true)

          saved_pony = result.object

          result = mapper_builder.call.find(saved_pony.id)
          expect(result.success?).to eq(true)

          found_pony = result.object

          expect(found_pony.name).to eq('Daylight Twinkles')
          expect(found_pony.color).to eq('orange')
          expect(found_pony.mane_length).to eq(25)
          expect(found_pony.unicorn).to eq(true)

          found_pony.color = 'carrot orange'
          result = mapper_builder.call.save(found_pony)
          expect(result.success?).to eq(true)

          result = mapper_builder.call.find(found_pony.id)
          expect(result.success?).to eq(true)

          found_pony = result.object

          expect(found_pony.color).to eq('carrot orange')
        end

        it 'can validate uniqueness' do
          daylight_twinkles = Pwny::Models::Pony.new(
            name: 'Daylight Twinkles',
            color: 'orange',
            mane_length: 25,
            unicorn: true,
            pegasus: false,
            unique_id: 1
          )

          super_sparkles = Pwny::Models::Pony.new(
            name: 'Super Sparkles',
            color: 'red',
            mane_length: 31,
            unicorn: true,
            pegasus: true,
            unique_id: 1
          )

          result = mapper_builder.call.save(daylight_twinkles)
          expect(result.success?).to eq(true)

          result = mapper_builder.call.save(super_sparkles)

          expect(result.success?).to eq(false)
        end

        describe '#count' do
          before do
            FactoryGirl.create_list(:pony, 5)
          end

          it 'gets the total number of stored records' do
            result = mapper_builder.call.count
            expect(result.object).to eq(5)
          end
        end
      end
    end
  end

  [:active_record, :memory].each do |adapter_type|
    describe 'hard deletion' do
      context "when adapter ':#{adapter_type}' is used" do
        before do
          Pwny::Application.default_adapter_type = adapter_type
        end

        let(:mapper) { Pwny::Mappers::PonyMapper.new }
        let(:pony) { FactoryGirl.create(:pony) }

        it 'deletes the pony' do
          result = mapper.hard_delete(pony)
          expect(result.success?).to eq(true)

          result = mapper.find(pony.id)
          expect(result.success?).to eq(false)
          expect(result.errors.first.title).to eq('not_found')
        end
      end
    end

    describe 'soft deletion' do
      context "when adapter ':#{adapter_type}' is used" do
        before do
          Pwny::Application.default_adapter_type = adapter_type
        end

        let(:mapper) { Pwny::Mappers::PonyMapper.new }
        let(:pony) { FactoryGirl.create(:pony) }

        it 'sets the deleted_at timestamp' do
          result = mapper.soft_delete(pony)
          expect(result.success?).to eq(true)
          expect(result.object.deleted_at).to be_within(1).of(Time.now)

          result = mapper.filter({}).to_result
          expect(result.success?).to eq(true)
          expect(result.object.count).to eq(0)

          result = mapper.filter({deleted_at: Quiver::Action::FilterValue.with(String, :presence).new({'nil' => 'false'})}).to_result
          expect(result.success?).to eq(true)
          expect(result.object.count).to eq(1)
        end
      end
    end

    describe 'restoring soft deleted record' do
      context "when adapter ':#{adapter_type}' is used" do
        before do
          Pwny::Application.default_adapter_type = adapter_type
        end

        let(:mapper) { Pwny::Mappers::PonyMapper.new }
        let(:pony) { FactoryGirl.create(:pony, :deleted) }

        it 'removes the deleted_at timestamp' do
          result = mapper.restore(pony)
          expect(result.success?).to eq(true)
          expect(result.object.deleted_at).to be_nil
        end
      end
    end
  end

  [:active_record, :memory].each do |adapter_type|
    context 'timestamps' do
      context "when adapter ':#{adapter_type}' is used" do
        before do
          Pwny::Application.default_adapter_type = adapter_type
        end

        let(:mapper) { Pwny::Mappers::PonyMapper.new }

        context 'updated_at' do
          let!(:pony) { Timecop.freeze(Time.now - 3600) { FactoryGirl.create(:pony) } }

          it 'is set to current time on update' do
            result = mapper.save(mapper.find(pony.id).object)

            expect(result.success?).to eq(true)
            expect(result.object.updated_at).to be_within(1).of(Time.now)
          end
        end
      end
    end
  end

  [:active_record, :memory].each do |adapter_type|
    context 'mapping to multiple tables (mostly relevant to active record adapter)' do
      context "when adapter ':#{adapter_type}' is used" do
        before do
          Pwny::Application.default_adapter_type = adapter_type
        end

        let(:mapper) { Pwny::Mappers::DragonMapper.new }

        context 'modern dragons' do
          it 'persists properly' do
            dragon = Pwny::Models::ModernDragon.new(
              name: 'Dr. Drake',
              color: 'gold',
              size: 450,
              twitter_followers: 'profDrag0n, mr_snow',
              jobs: [
                Pwny::Models::Job.new(
                  position: 'Doctor',
                  company_name: "St. Trogdor's Legacy Hospital"
                ),
                Pwny::Models::Job.new(
                  position: 'Dynamic Configuration Director',
                  company_name: "Techidax"
                )
              ]
            )

            result = mapper.save(dragon)
            expect(result.success?).to eq(true)

            result = mapper.find(dragon.id)
            expect(result.success?).to eq(true)

            persisted_dragon = result.object

            expect(persisted_dragon.class).to eq(Pwny::Models::ModernDragon)
            expect(persisted_dragon).to have_attributes(
              name: 'Dr. Drake',
              color: 'gold',
              size: 450,
              twitter_followers: 'profDrag0n, mr_snow',
              jobs: [kind_of(Pwny::Models::Job), kind_of(Pwny::Models::Job)]
            )

            expect(persisted_dragon.jobs.find { |j| j.position == 'Doctor' }.company_name).to eq("St. Trogdor's Legacy Hospital")
            expect(persisted_dragon.jobs.find { |j| j.position == 'Dynamic Configuration Director' }.company_name).to eq("Techidax")

            persisted_dragon.jobs.pop
            persisted_dragon.jobs << Pwny::Models::Job.new(
              company_name: 'Veridian Dynamics',
              position: 'CTO'
            )

            persisted_dragon.size = 460

            result = mapper.save(persisted_dragon)
            expect(result.success?).to eq(true)

            result = mapper.find(dragon.id)
            expect(result.success?).to eq(true)

            persisted_dragon = result.object

            expect(persisted_dragon.class).to eq(Pwny::Models::ModernDragon)
            expect(persisted_dragon).to have_attributes(
              name: 'Dr. Drake',
              color: 'gold',
              size: 460,
              twitter_followers: 'profDrag0n, mr_snow',
              jobs: [kind_of(Pwny::Models::Job), kind_of(Pwny::Models::Job)]
            )

            expect(persisted_dragon.jobs.find { |j| j.position == 'Doctor' }.company_name).to eq("St. Trogdor's Legacy Hospital")
            expect(persisted_dragon.jobs.find { |j| j.position == 'CTO' }.company_name).to eq("Veridian Dynamics")
          end
        end

        context 'classic dragons' do
          it 'persists properly' do
            dragon = Pwny::Models::ClassicDragon.new(
              name: 'Nerroth Bringer of Death',
              color: 'green',
              size: 15600,
              gold_count: 519857,
              piles_of_bones: 1 # it's a really big pile
            )

            result = mapper.save(dragon)
            expect(result.success?).to eq(true)

            result = mapper.find(dragon.id)
            expect(result.success?).to eq(true)

            persisted_dragon = result.object

            expect(persisted_dragon.class).to eq(Pwny::Models::ClassicDragon)
            expect(persisted_dragon).to have_attributes(
              name: 'Nerroth Bringer of Death',
              color: 'green',
              size: 15600,
              gold_count: 519857,
              piles_of_bones: 1
            )

            persisted_dragon.size = 15500
            persisted_dragon.gold_count = 519900

            result = mapper.save(persisted_dragon)
            expect(result.success?).to eq(true)

            result = mapper.find(dragon.id)
            expect(result.success?).to eq(true)

            persisted_dragon = result.object

            expect(persisted_dragon.class).to eq(Pwny::Models::ClassicDragon)
            expect(persisted_dragon).to have_attributes(
              name: 'Nerroth Bringer of Death',
              color: 'green',
              size: 15500,
              gold_count: 519900,
              piles_of_bones: 1
            )
          end
        end
      end
    end
  end

  context 'memory only' do
    before do
      Pwny::Application.default_adapter_type = :memory
    end

    let(:mapper) { Pwny::Mappers::DragonMapper.new }

    it 'hooks allow for data to be modified while between adapter and mapper' do
      dragon = Pwny::Models::ModernDragon.new(
        name: 'Dr. Drake',
        color: 'gold',
        size: 450,
        twitter_followers: 'profDrag0n, mr_snow',
        secret: 'is friends with ponies',
        jobs: [
          Pwny::Models::Job.new(
            position: 'Doctor',
            company_name: "St. Trogdor's Legacy Hospital"
          )
        ]
      )

      result = mapper.save(dragon)
      expect(result.success?).to eq(true)

      raw_dragon = Pwny::Application.memory_adapter_store.get('dragon_mapper')[dragon.id]

      totally_encrypted_secret = raw_dragon[:encrypted_secret]
      decrypted_secret = Base64.decode64(totally_encrypted_secret)
      expect(decrypted_secret).to eq(dragon.secret)

      result = mapper.find(dragon.id)
      expect(result.success?).to eq(true)
      expect(result.object.secret).to eq(dragon.secret)
    end
  end

  context 'active record only' do
    before do
      Pwny::Application.default_adapter_type = :active_record
    end

    let(:mapper) { Pwny::Mappers::DragonMapper.new }

    let(:modern_dragon_attributes) {
      Class.new(ActiveRecord::Base) do
        self.table_name = 'modern_dragon_attributes'
      end
    }

    let(:modern_dragon_jobs) {
      Class.new(ActiveRecord::Base) do
        self.table_name = 'modern_dragon_jobs'
      end
    }

    it 'properly deletes all the tables' do
      dragon = Pwny::Models::ModernDragon.new(
        name: 'Dr. Drake',
        color: 'gold',
        size: 450,
        twitter_followers: 'profDrag0n, mr_snow',
        secret: 'is friends with ponies',
        jobs: [
          Pwny::Models::Job.new(
            position: 'Doctor',
            company_name: "St. Trogdor's Legacy Hospital"
          )
        ]
      )

      result = mapper.save(dragon)
      expect(result.success?).to eq(true)

      result = mapper.hard_delete(dragon)
      expect(result.success?).to eq(true)

      expect(modern_dragon_jobs.count).to eq(0)
      expect(modern_dragon_attributes.count).to eq(0)
    end

    it 'runs multiple table mapping creates within a transaction' do
      dragon = Pwny::Models::ModernDragon.new(
        name: 'Dr. Drake',
        color: 'gold',
        size: 450,
        twitter_followers: 'profDrag0n, mr_snow',
        jobs: [
          Pwny::Models::Job.new(
            position: 'Doctor',
            company_name: "St. Trogdor's Legacy Hospital"
          ),
          Pwny::Models::Job.new(
            position: 'Doctor',
            company_name: "Hoard Legacy Hospital"
          )
        ]
      )

      result = mapper.save(dragon)
      expect(result.success?).to eq(false)

      expect(mapper.count.object).to eq(0)
    end

    it 'runs multiple table mapping updates within a transaction' do
      dragon = Pwny::Models::ModernDragon.new(
        name: 'Dr. Drake',
        color: 'gold',
        size: 450,
        twitter_followers: 'profDrag0n, mr_snow',
        jobs: [
          Pwny::Models::Job.new(
            position: 'Doctor',
            company_name: "St. Trogdor's Legacy Hospital"
          ),
          Pwny::Models::Job.new(
            position: 'CEO',
            company_name: "Hoard Legacy Hospital"
          )
        ]
      )

      result = mapper.save(dragon)
      expect(result.success?).to eq(true)
      dragon = result.object

      dragon.size = 100
      dragon.jobs.pop
      dragon.jobs << Pwny::Models::Job.new(
        position: 'Doctor',
        company_name: 'Hoard Legacy Hospital'
      )

      result = mapper.save(dragon)

      expect(result.success?).to eq(false)

      persisted_dragon = mapper.find(dragon.id).object
      expect(persisted_dragon.size).to eq(450)
    end
  end
end
