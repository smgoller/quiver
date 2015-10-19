FactoryGirl.define do
  factory :pony, class: Pwny::Models::Pony do
    name { FFaker::Name.name }
    color { FFaker::Color.name }
    mane_length { 10 }
    unique_id { rand(1_999_999_999) }

    to_create do |instance|
      result = Pwny::Mappers::PonyMapper.new.save(instance)
    end

    trait :deleted do
      deleted_at { Time.now }
    end
  end
end
