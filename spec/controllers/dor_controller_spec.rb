require 'spec_helper'

describe DorController, :type => :controller do
  describe 'reindex' do
    before :each do
      @mock_druid     = 'asdf:1234'
      @mock_logger    = double(Logger)
      @mock_solr_conn = double(Dor::SearchService.solr)
      @mock_req_uuid  = 'ab12-cd34-ef56'
      @mock_solr_doc  = {id: @mock_druid, text_field_tesim: 'a field to be searched'}

      log_in_as_mock_user(subject)
      expect(Argo::Indexer).to receive(:generate_index_logger).and_return(@mock_logger)
    end
    context 'from a referrer' do
      before :each do
        request.env['HTTP_REFERER'] = root_path
      end
      it 'should reindex an object' do
        expect(Argo::Indexer).to receive(:reindex_pid)
          .with(@mock_druid, @mock_logger).and_return(@mock_solr_doc)
        expect(Dor::SearchService).to receive(:solr).and_return(@mock_solr_conn)
        expect(@mock_solr_conn).to receive(:commit)
        get :reindex, :pid => @mock_druid
        expect(flash[:notice]).to eq 'Successfully updated index for asdf:1234'
        expect(response.code).to eq '302'
      end

      it 'should give the right status if an object is not found' do
        expect(Argo::Indexer).to receive(:reindex_pid)
          .with(@mock_druid, @mock_logger).and_raise(ActiveFedora::ObjectNotFoundError)
        get :reindex, :pid => @mock_druid
        expect(flash[:error]).to eq 'Object does not exist in Fedora.'
        expect(response.code).to eq '302'
      end
    end
    context 'without a referrer' do
      it 'should reindex an object' do
        expect(Argo::Indexer).to receive(:reindex_pid)
          .with(@mock_druid, @mock_logger).and_return(@mock_solr_doc)
        expect(Dor::SearchService).to receive(:solr).and_return(@mock_solr_conn)
        expect(@mock_solr_conn).to receive(:commit)
        get :reindex, :pid => @mock_druid
        expect(response.body).to eq 'Successfully updated index for asdf:1234'
        expect(response.code).to eq '200'
      end

      it 'should give the right status if an object is not found' do
        expect(Argo::Indexer).to receive(:reindex_pid)
          .with(@mock_druid, @mock_logger).and_raise(ActiveFedora::ObjectNotFoundError)
        get :reindex, :pid => @mock_druid
        expect(response.body).to eq 'Object does not exist in Fedora.'
        expect(response.code).to eq '404'
      end
    end
  end

  describe 'dor indexing' do
    before :each do
      log_in_as_mock_user(subject)
      item = instantiate_fixture('druid_bb001zc5754', Dor::Item)
      allow(item.descMetadata).to receive(:new?).and_return(false)
      allow(item.descMetadata).to receive(:ng_xml).and_return(Nokogiri::XML('<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
      <mods:titleInfo>
      <mods:title>AMERICA cum Supplementis PolyGlottis</mods:title>
      </mods:titleInfo>
      </mods:mods>'))
      expect(item.workflows).to receive(:content).and_return '<workflows objectId="druid:bx756pk3634"></workflows>'
      allow(item).to receive(:milestones).and_return []
      allow(item).to receive(:released_for).and_return []
      allow(item).to receive(:new_version_open?).and_return false
      allow(item).to receive(:archive_workflows)
      @solr_doc = item.to_solr
    end

    it 'the indexer should generate gryphondor fields' do
      expect(@solr_doc).to match a_hash_including('public_dc_title_tesim' => ['AMERICA cum Supplementis PolyGlottis'])
    end

    it 'relevant gdor fields should be present in the hash' do
      # these are NOT guaranteed:
      #    sw_subject_temporal_tesim
      #    sw_subject_geographic_tesim
      #    sw_pub_date_sort_ssi
      #    sw_pub_date_facet
      # these are guaranteed (have a default-fill value)
      %w(
        sw_language_tesim
        sw_genre_tesim
        sw_format_tesim
      ).each do |key|
        expect(@solr_doc).to match a_hash_including(key)
      end
    end

    it 'all of the solr fields argo depends on should be in a solr doc generated by to_solr' do
      skip 'unimplemented: required fields not fully/uniquely identified'
    end
  end

  describe 'delete_from_index' do
    it 'should remove an object from the index' do
      log_in_as_mock_user(subject)
      expect(Dor::SearchService.solr).to receive(:delete_by_id).with('asdf:1234')
      get :delete_from_index, :pid => 'asdf:1234'
    end
  end

  describe 'republish' do
    it 'should republish' do
      log_in_as_mock_user(subject)
      mock_item = double()
      expect(mock_item).to receive(:publish_metadata_remotely)
      allow(Dor::Item).to receive(:find).and_return(mock_item)
      get :republish, :pid => 'druid:123'
    end
  end
end
