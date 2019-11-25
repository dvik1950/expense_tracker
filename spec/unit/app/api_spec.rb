require_relative '../../../app/api'
require 'rack/test'


module ExpenseTracker

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end


    def parsed
      JSON.parse(last_response.body)
    end


    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    context 'when the expense is successfully recorded' do
      let(:expense) { { 'some' => 'data' } }
      before do
        allow(ledger).to receive(:record)
                             .with(expense)
                             .and_return(RecordResult.new(true, 417, nil))
      end

      it 'returns the expense id' do
        post '/expenses', JSON.generate(expense)
        expect(parsed).to include('expense_id' => 417)
      end

      it 'responds with a 200 (OK)' do
        post '/expenses', JSON.generate(expense)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when the expense fails validation' do
      let(:expense) { { 'some' => 'data' } }

      before do
        allow(ledger).to receive(:record)
                             .with(expense)
                             .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
      end

      it 'returns an error message' do
        post '/expenses', JSON.generate(expense)
        expect(parsed).to include('error' => 'Expense incomplete')
      end

      it 'responds with a 422 (Unprocessable entity)' do
        post '/expenses', JSON.generate(expense)
        expect(last_response.status).to eq(422)
      end
    end

    describe 'GET /expenses/:date' do

      context 'when expenses exist on the given date' do

        before do
          allow(ledger).to receive(:expenses_on)
                               .with('2017-06-11')
                               .and_return(['expense_1', 'expense_2'])
        end

        it 'returns the expense records as JSON' do
          get 'expenses/2017-06-11'
          expect(parsed).to include(
                                'payee' => 'Whole Foods',
                                'amount' => 95.20,
                                'date' => '2017-06-11'
                            )
        end

        it 'responds with a 200 (OK)' do
          get 'expenses/2017-06-10'
          expect(last_response.status).to eq(200)
        end
      end
      context 'when there are no expenses on the given date' do
        it 'returns an empty array as JSON' do
          get 'expenses/2000-06-10'
          expect(parsed).to eq([])
        end
        it 'responds with a 200 (OK)' do
          get 'expenses/2000-06-10'
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end