module Pwny::Adapters
  module DragonMapper
    class ActiveRecordAdapter
      include Quiver::Adapter
      include Quiver::Adapter::ActiveRecordHelpers

      primary_key_name :id

      define_record_class 'DragonRecord', table: 'dragons'
      define_record_class 'ModernDragonAttributesRecord', table: 'modern_dragon_attributes'
      define_record_class 'ModernDragonJobRecord', table: 'modern_dragon_jobs'
      define_record_class 'ClassicDragonAttributesRecord', table: 'classic_dragon_attributes'
      use_record_class 'DragonRecord'

      private

      def mappings(attributes, p)
        p.map(
          attributes.slice(:name, :color, :size),
          to: 'DragonRecord',
          primary: true
        )

        case attributes[:type]
        when :modern_dragon
          p.map(
            attributes.slice(:twitter_followers),
            to: 'ModernDragonAttributesRecord',
            foreign_key: {dragon_id: p.primary_key}
          )
          p.map_array(
            {jobs: attributes[:jobs].map(&:attributes)},
            to: 'ModernDragonJobRecord',
            foreign_key: {dragon_id: p.primary_key}
          )
        when :classic_dragon
          p.map(
            attributes.slice(:gold_count, :piles_of_bones),
            to: 'ClassicDragonAttributesRecord',
            foreign_key: {dragon_id: p.primary_key}
          )
        end
      end

      def load_additional(items)
        ids = items.select do |item|
          item[:type] == 'modern_dragon'
        end.map do |item|
          item[:id]
        end

        jobs = self.class.record_classes['ModernDragonJobRecord'].where(dragon_id: ids).map(&:attributes)

        grouped_jobs = jobs.group_by do |job|
          job['dragon_id']
        end

        items.each do |item|
          if grouped_jobs[item[:id]]
            item[:jobs] = grouped_jobs[item[:id]]
          end
        end

        items
      end

      def base_query
        default_record_class
          .select(<<-SQL)
            dragons.*,
            modern_dragon_attributes.twitter_followers AS twitter_followers,
            classic_dragon_attributes.gold_count AS gold_count,
            classic_dragon_attributes.piles_of_bones AS piles_of_bones
          SQL
          .group('dragons.id')
          .joins("LEFT JOIN modern_dragon_attributes ON modern_dragon_attributes.dragon_id = dragons.id AND dragons.type = 'modern_dragon'")
          .joins("LEFT JOIN classic_dragon_attributes ON classic_dragon_attributes.dragon_id = dragons.id AND dragons.type = 'classic_dragon'")
      end
    end
  end
end
