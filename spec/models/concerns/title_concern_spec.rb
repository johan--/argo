# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TitleConcern do
  let(:document) { SolrDocument.new(document_attributes) }

  describe '#title' do
    context 'with data' do
      let(:document_attributes) { { SolrDocument::FIELD_TITLE => 'My title' } }

      it 'has a title' do
        expect(document.title).to eq('My title')
      end
    end

    context 'without data' do
      let(:document_attributes) { {} }

      it 'handles missing title' do
        expect(document.title).to be_nil
      end
    end
  end
end
