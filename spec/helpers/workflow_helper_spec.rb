require 'spec_helper'

describe WorkflowHelper do 
  describe 'render_workflow_archive_count' do
    it 'should render the count if there is one' do
      wf_name = "testWF"
      query_params = "objectType_facet:workflow workflow_name_s:#{wf_name}"
      archived_disp_str = '42'
      query_results = double('query_results', :docs => [{"#{wf_name}_archived_display" => [archived_disp_str]}])

      Dor::SearchService.stub(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq(archived_disp_str.to_i)
    end
    it 'should return hyphen if it cannot get query results' do
      wf_name = "testWF"
      query_params = "objectType_facet:workflow workflow_name_s:#{wf_name}"
      query_results = nil

      Dor::SearchService.stub(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq("-")
    end
    it 'should return hyphen if it cannot get a count from query results' do
      wf_name = "testWF"
      query_params = "objectType_facet:workflow workflow_name_s:#{wf_name}"
      query_results = double('query_results', :docs => [{'wrong_field' => 'wrong value'}])

      Dor::SearchService.stub(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq("-")
    end
  end
end