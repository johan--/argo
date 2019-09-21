# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatkeyConcern do
  let(:document) { SolrDocument.new(document_attributes) }

  describe '#catkey' do
    describe 'without one present' do
      let(:document_attributes) { {} }

      it 'returns nil' do
        expect(document.catkey).to be_nil
        expect(document.catkey_id).to be_nil
      end
    end

    describe 'when a catkey is present' do
      let(:document_attributes) { { SolrDocument::FIELD_CATKEY_ID => ['catkey:8675309'] } }

      it 'returns catkey value' do
        expect(document.catkey).to eq 'catkey:8675309'
        expect(document.catkey_id).to eq '8675309'
      end
    end
  end
end
