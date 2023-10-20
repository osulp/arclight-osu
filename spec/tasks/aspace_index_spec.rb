# frozen_string_literal: true

require 'rails_helper'
Rails.application.load_tasks

RSpec.describe 'Rake tasks' do
  describe 'arclight_osu:aspace_index' do
    let(:run_rake_task) do
      Rake.application['arclight_osu:aspace_index'].execute
    end

    context 'when aspace is not working' do
      it 'raises Errno::EADDRNOTAVAIL' do
        expect { run_rake_task }.to raise_error(Errno::EADDRNOTAVAIL)
      end

      it 'does not index anything' do
        expect { SolrDocument.find('0') }.to raise_error(Blacklight::Exceptions::RecordNotFound)
      end
    end

    context 'when aspace is working' do
      before do
        stub_request(:post, 'http://localhost:3001/users/test/login')
          .to_return(status: 200, body: { session: 'token' }.to_json)
        stub_request(:get, 'http://localhost:3001/repositories')
          .to_return(status: 200, body: [{ position: 1 }].to_json)
        stub_request(:get, 'http://localhost:3001/repositories/1/resources?all_ids=true')
          .to_return(status: 200, body: [0].to_json)
        stub_request(:get, 'http://localhost:3001/repositories/1/resource_descriptions/0.xml?ead3=false&include_daos=true')
          .to_return(status: 200, body: file_fixture('0_ead.xml').read.strip)
        run_rake_task
      end

      it 'creates a solr document' do
        expect(SolrDocument.find('0')).not_to be_nil
      end

      it 'indexes some metadata' do
        sd = SolrDocument.find('0')
        expect(sd['title_ssm']).to eq(['aaaaaaaaaaaaaa magarac'])
      end
    end
  end
end
