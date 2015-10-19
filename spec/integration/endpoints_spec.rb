require 'spec_helper'

describe 'Endpoints' do
  %i|active_record memory|.each do |adapter_type|
    describe "ponies index with #{adapter_type} adapter" do
      before do
        Pwny::Application.default_adapter_type = adapter_type
      end

      let!(:ponies) { FactoryGirl.create_list(:pony, 3, color: 'orange', mane_length: 30) }

      it 'returns all the ponies' do
        response = Pwny::Endpoints::Ponies::Index.new.call({})
        response_body = response.last.join('')
        parsed_response = JSON.parse(response_body)

        expect(parsed_response['data'].map { |i| i['name'] }).to eq(ponies.map(&:name))
      end

      it 'returns a type on each pony' do
        response = Pwny::Endpoints::Ponies::Index.new.call({})
        response_body = response.last.join('')
        parsed_response = JSON.parse(response_body)

        expect(
          parsed_response['data'].map { |i| i['type'] }.uniq
        ).to eq(['ponies'])
      end

      context 'with pagination' do
        let!(:ponies) { FactoryGirl.create_list(:pony, 30) }

        it 'can limit the number of ponies returned to 5' do
          response = Pwny::Endpoints::Ponies::Index.new.call('page' => {'limit' => 5}, 'PATH_INFO' => '/ponies', 'QUERY_STRING' => 'page[limit]=5')
          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].count).to eq(5)
          expect(parsed_response['data'].map { |i| i['name'] }).to eq(ponies[0..4].map(&:name))
          expect(parsed_response['links']['next']).to include('/ponies?page[limit]=5&page[offset]=5')
          expect(parsed_response['meta']['page']['total']).to eq(30)
          expect(parsed_response['meta']['page']['offset']).to eq(0)
          expect(parsed_response['meta']['page']['limit']).to eq(5)
        end

        it 'can limit to 5 and offset to 4' do
          response = Pwny::Endpoints::Ponies::Index.new.call('page' => {'limit' => 5, 'offset' => 4}, 'PATH_INFO' => '/ponies', 'QUERY_STRING' => 'page[limit]=5&page[offset]=4')
          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].count).to eq(5)
          expect(parsed_response['data'].map { |i| i['name'] }).to eq(ponies[4..8].map(&:name))
          expect(parsed_response['links']['next']).to include('/ponies?page[limit]=5&page[offset]=9')
          expect(parsed_response['meta']['page']['total']).to eq(30)
          expect(parsed_response['meta']['page']['offset']).to eq(4)
          expect(parsed_response['meta']['page']['limit']).to eq(5)
        end
      end

      context 'with sorting' do
        let!(:more_ponies) { FactoryGirl.create_list(:pony, 3, color: 'purple', mane_length: 10) }
        let!(:extra_pony) { FactoryGirl.create(:pony, color: 'purple', mane_length: 20) }

        it 'sorts by mane_length ascending' do
          response = Pwny::Endpoints::Ponies::Index.new.call({sort: 'mane_length'})
          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].map { |i| i['mane_length'] }).to eq([10, 10, 10, 20, 30, 30, 30])
        end

        it 'sorts by mane_length descending' do
          response = Pwny::Endpoints::Ponies::Index.new.call({sort: '-mane_length'})
          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].map { |i| i['mane_length'] }).to eq([30, 30, 30, 20, 10, 10, 10])
        end

        it 'can sort by multiple attributes' do
          response = Pwny::Endpoints::Ponies::Index.new.call({sort: 'color,mane_length'})
          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].map { |i| i['mane_length'] }).to eq([30, 30, 30, 10, 10, 10, 20])
        end
      end

      context 'with filtering' do
        let!(:purple_ponies) { FactoryGirl.create_list(:pony, 2, color: 'purple') }
        let!(:orange_ponies) { FactoryGirl.create_list(:pony, 2, color: 'orange', mane_length: 50) }

        it 'returns all the purple ponies' do
          response = Pwny::Endpoints::Ponies::Index.new.call({
            filter: {
              color: {
                eq: 'purple'
              }
            }
          })

          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].count).to eq(2)
        end

        it 'returns all the long maned ponies' do
          response = Pwny::Endpoints::Ponies::Index.new.call({
            filter: {
              mane_length: {
                # 45 is a string because query params
                gt: '45'
              }
            }
          })

          response_body = response.last.join('')
          parsed_response = JSON.parse(response_body)

          expect(parsed_response['data'].count).to eq(2)
        end

        context 'with invalid filters' do
          it 'returns errors when the attribute key does not map to a hash' do
            response = Pwny::Endpoints::Ponies::Index.new.call({
              filter: {
                color: 'foo'
              }
            })

            response_body = response.last.join('')
            parsed_response = JSON.parse(response_body)

            expect(parsed_response['errors'].count).to eq(1)
            error = parsed_response['errors'].first

            expect(error['status']).to eq('422')
            expect(error['code']).to eq('filter_error')
            expect(error['detail']).to eq('color: filters must be a Hash')
          end

          it 'returns errors when the comparator is unsupported for the attribute' do
            response = Pwny::Endpoints::Ponies::Index.new.call({
              filter: {
                color: {
                  lt: 3
                }
              }
            })

            response_body = response.last.join('')
            parsed_response = JSON.parse(response_body)

            expect(parsed_response['errors'].count).to eq(1)
            error = parsed_response['errors'].first

            expect(error['status']).to eq('422')
            expect(error['code']).to eq('filter_error')
            expect(error['detail']).to eq(%q|color: 'lt' is not supported|)
          end

          it 'returns errors when the comparator is just completely unsupported' do
            response = Pwny::Endpoints::Ponies::Index.new.call({
              filter: {
                color: {
                  foo: 3
                }
              }
            })

            response_body = response.last.join('')
            parsed_response = JSON.parse(response_body)

            expect(parsed_response['errors'].count).to eq(1)
            error = parsed_response['errors'].first

            expect(error['status']).to eq('422')
            expect(error['code']).to eq('filter_error')
            expect(error['detail']).to eq(%q|color: 'foo' is not supported|)
          end

          it 'returns errors when in is not given an array' do
            response = Pwny::Endpoints::Ponies::Index.new.call({
              filter: {
                color: {
                  in: 3
                }
              }
            })

            response_body = response.last.join('')
            parsed_response = JSON.parse(response_body)

            expect(parsed_response['errors'].count).to eq(1)
            error = parsed_response['errors'].first

            expect(error['status']).to eq('422')
            expect(error['code']).to eq('filter_error')
            expect(error['detail']).to eq(%q|color: 'in' must map to an Array|)
          end

          it 'returns errors when gt is given an array' do
            response = Pwny::Endpoints::Ponies::Index.new.call({
              filter: {
                mane_length: {
                  gt: [1, 2, 3]
                }
              }
            })

            response_body = response.last.join('')
            parsed_response = JSON.parse(response_body)

            expect(parsed_response['errors'].count).to eq(1)
            error = parsed_response['errors'].first

            expect(error['status']).to eq('422')
            expect(error['code']).to eq('filter_error')
            expect(error['detail']).to eq(%q|mane_length: 'gt' must not map to Hashes or Arrays|)
          end
        end
      end
    end

    describe "ponies show with #{adapter_type} adapter" do
      before do
        Pwny::Application.default_adapter_type = adapter_type
      end

      let!(:pony) { FactoryGirl.create(:pony) }

      it 'returns the one pony' do
        response = Pwny::Endpoints::Ponies::Show.new.call({id: pony.id})
        response_body = response.last.join('')
        parsed_response = JSON.parse(response_body)

        expect(parsed_response['data'].map { |i| i['name'] }).to eq([pony.name])
      end
    end
  end
end
