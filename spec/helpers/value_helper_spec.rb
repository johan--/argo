require 'spec_helper'

RSpec.describe ValueHelper do
  let(:document) { SolrDocument.new(document_attributes) }
  let(:args) { { document: document, value: value } }
  describe '#link_to_admin_policy' do
    let(:value) { 'druid:yolo' }
    let(:document_attributes) do
      {
        SolrDocument::FIELD_APO_TITLE => ['Y.O.L.O.'],
        SolrDocument::FIELD_APO_ID => [value]
      }
    end
    it 'creates a link to the admin policies catalog path' do
      puts helper.link_to_admin_policy(args)
      expect(helper.link_to_admin_policy(args))
        .to have_css 'a[href="/catalog/druid:yolo"]', text: 'Y.O.L.O.'
    end
  end
  describe '#links_to_collections' do
    let(:value) do
      ['info:fedora/druid:supercool', 'info:fedora/druid:extracool']
    end
    let(:document_attributes) do
      { SolrDocument::FIELD_COLLECTION_TITLE => ['Super Cool', 'Extra Cool'] }
    end
    it 'creates multiple links delimited by a line break' do
      expect(helper.links_to_collections(args))
        .to have_css 'a[href="/catalog/druid:supercool"]', text: 'Super Cool'
      expect(helper.links_to_collections(args))
        .to have_css 'a[href="/catalog/druid:extracool"]', text: 'Extra Cool'
      expect(helper.links_to_collections(args)).to have_css 'br'
    end
  end
end