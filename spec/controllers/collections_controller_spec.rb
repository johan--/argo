# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionsController do
  before do
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(controller).to receive(:authorize!).with(:manage_item, Dor::AdminPolicyObject).and_return(true)
    sign_in user
  end

  let(:user) { create(:user) }
  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }

  describe '#new' do
    it 'is successful' do
      get :new, params: { apo_id: apo.pid }
      expect(assigns[:apo]).to eq apo
      expect(response).to be_successful
    end
  end

  describe '#create' do
    before do
      allow(apo).to receive(:save)

      allow(Dor).to receive(:find).with(collection.pid).and_return(collection)
      allow(collection).to receive(:save)
      allow(collection).to receive(:update_index)
    end

    it 'creates a collection via catkey' do
      catkey = '1234567'
      expect(Dor::Services::Client.objects).to receive(:register) do |params|
        expect(params[:params]).to match a_hash_including(
          label: ':auto',
          object_type: 'collection',
          admin_policy: apo.pid,
          other_id: 'symphony:' + catkey,
          metadata_source: 'symphony',
          rights: 'dark'
        )
        { pid: collection.pid }
      end
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name)
        .with(collection.pid, 'accessionWF', version: '1')

      post :create, params: { 'label' => ':auto',
                              'collection_catkey' => catkey,
                              'collection_rights_catkey' => 'dark',
                              apo_id: apo.pid }
      expect(response).to be_redirect # redirects to catalog page
    end

    it 'creates a collection from title/abstract by registering the collection, then adding the abstract' do
      title = 'collection title'
      abstract = 'this is the abstract'
      mock_desc_md_ds = double(Dor::DescMetadataDS)
      expect(mock_desc_md_ds).to receive(:abstract=).with(abstract)
      expect(mock_desc_md_ds).to receive(:ng_xml)
      expect(mock_desc_md_ds).to receive(:content=)
      expect(mock_desc_md_ds).to receive(:save)

      expect(Dor::Services::Client.objects).to receive(:register) do |params|
        expect(params[:params]).to match a_hash_including(
          label: title,
          object_type: 'collection',
          admin_policy: apo.pid,
          metadata_source: 'label',
          rights: 'dark'
        )
        { pid: collection.pid }
      end
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name)
        .with(collection.pid, 'accessionWF', version: '1')
      expect(collection).to receive(:descMetadata).and_return(mock_desc_md_ds).exactly(4).times

      post :create, params: { 'collection_title' => title,
                              'collection_abstract' => abstract,
                              'collection_rights' => 'dark',
                              apo_id: apo.pid }
      expect(response).to be_redirect # redirects to catalog page
    end

    it 'adds the collection to the apo default collection list' do
      title = 'collection title'
      abstract = 'this is the abstract'
      expect(Dor::Services::Client.objects).to receive(:register) do |params|
        expect(params[:params]).to match a_hash_including(
          label: title,
          object_type: 'collection',
          admin_policy: apo.pid,
          metadata_source: 'label',
          rights: 'dark'
        )
        { pid: collection.pid }
      end
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name)
        .with(collection.pid, 'accessionWF', version: '1')

      expect_any_instance_of(CollectionForm).to receive(:sync)
      expect(apo).to receive(:add_default_collection).with(collection.pid)

      post :create, params: { 'collection_title' => title,
                              'collection_abstract' => abstract,
                              'collection_rights' => 'dark',
                              apo_id: apo.pid }
      expect(response).to be_redirect # redirects to catalog page
    end
  end

  describe '#exists' do
    let(:title) { 'foo' }
    let(:catkey) { '123' }

    it 'returns true if collection with title exists' do
      allow(Dor::Collection).to receive(:where).and_return([1])
      expect(Dor::Collection).to receive(:where).with(title_ssi: title)
      post :exists, params: {
        'title' => title
      }
      expect(response.body).to eq('true')
    end
    it 'returns false if collection with title exists' do
      allow(Dor::Collection).to receive(:where).and_return([])
      expect(Dor::Collection).to receive(:where).with(title_ssi: title)
      post :exists, params: {
        'title' => title
      }
      expect(response.body).to eq('false')
    end
    it 'returns true if collection with catkey exists' do
      allow(Dor::Collection).to receive(:where).and_return([1])
      expect(Dor::Collection).to receive(:where).with(identifier_ssim: "catkey:#{catkey}")
      post :exists, params: {
        'catkey' => catkey
      }
      expect(response.body).to eq('true')
    end
    it 'returns false if collection with catkey exists' do
      allow(Dor::Collection).to receive(:where).and_return([])
      expect(Dor::Collection).to receive(:where).with(identifier_ssim: "catkey:#{catkey}")
      post :exists, params: {
        'catkey' => catkey
      }
      expect(response.body).to eq('false')
    end
    it 'returns true if collection with title and catkey exists' do
      allow(Dor::Collection).to receive(:where).and_return([1])
      expect(Dor::Collection).to receive(:where).with(title_ssi: title, identifier_ssim: "catkey:#{catkey}")
      post :exists, params: {
        'title' => title,
        'catkey' => catkey
      }
      expect(response.body).to eq('true')
    end
  end
end
