# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))

    allow(Dor).to receive(:find).with(dor_registration[:pid]).and_return(mock_object)
  end

  let(:mock_object) { instance_double(Dor::Item, update_index: true) }
  let(:workflow_service) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
  let(:dor_registration) { { pid: 'druid:abc' } }

  describe '#create' do
    context 'when register is successful' do
      let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: dor_registration) }

      before do
        allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
        allow(Dor::Config.workflow).to receive(:client).and_return(workflow_service)
      end

      it 'registers the object' do
        post :create, params: {
          object_type: 'item',
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          metadata_source: 'label',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Book (ltr)',
                'Registered By : jcoyne85'],
          rights: 'default',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
        expect(response).to be_redirect
        expect(objects_client).to have_received(:register).with(
          params: {
            object_type: 'item',
            admin_policy: 'druid:hv992ry2431',
            collection: 'druid:hv992ry7777',
            metadata_source: 'label',
            label: 'test parameters for registration',
            tag: ['Process : Content Type : Book (ltr)',
                  'Registered By : jcoyne85'],
            rights: 'default',
            source_id: 'foo:bar',
            other_id: 'label:'
          }
        )
        expect(workflow_service).to have_received(:create_workflow_by_name).with('druid:abc', 'registrationWF')
      end
    end

    context 'when register is a conflict' do
      let(:message) { "Conflict: 409 (An object with the source ID 'sul:36105226711146' has already been registered" }

      before do
        allow(Dor::Services::Client.objects)
          .to receive(:register)
          .and_raise(Dor::Services::Client::UnexpectedResponse, message)
      end

      it 'shows an error' do
        post :create
        expect(response.status).to eq 409
        expect(response.body).to eq message
      end
    end
  end
end
