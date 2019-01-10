# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  describe '#views_to_switch' do
    it 'returns the view switchers' do
      helper.views_to_switch.each do |view|
        expect(view).to be_an ViewSwitcher
      end
    end
  end

  describe '#search_of_pids' do
    context 'when nil' do
      it 'returns an empty string' do
        expect(helper.search_of_pids(nil)).to eq ''
      end
    end

    context 'when a Blacklight::Search' do
      it 'adds a pids_only param' do
        search = Search.new
        search.query_params = { q: 'cool catz' }
        expect(helper.search_of_pids(search)).to include(q: 'cool catz', 'pids_only' => true)
      end
    end
  end
end
