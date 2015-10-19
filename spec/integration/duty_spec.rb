require 'spec_helper'

describe 'Duty' do
  before do
    Pwny::Application.default_adapter_type = :memory
  end

  %i|memory delayed_job|.each do |backing|
    context "with #{backing}-backed queue" do
      let(:organizer) { FactoryGirl.create(:pony, reputation: 5) }

      before do
        Pwny::Application.default_duty_queue_backend = backing
      end

      it 'changes the reputation from 5 to 10' do
        party_duty = Pwny::Duties::PartyDuty.new(
          organizer.id,
          "Astra's birthday",
          5
        )

        Pwny::DutyMaster.new.queue(party_duty)

        expect do
          Pwny::DutyTestHelper.new.carry_out(1)
        end.to change {
          Pwny::Mappers::PonyMapper.new.find(organizer.id).object.reputation
        }.from(5).to(10)
      end
    end
  end
end
