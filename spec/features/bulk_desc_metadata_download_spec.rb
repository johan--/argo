require 'spec_helper'

RSpec.feature 'Bulk Descriptive Metadata Download' do
  let(:current_user) { create(:user) }
  before(:each) do
    expect(current_user).to receive(:to_s).at_least(:once).and_return('name')
    # Needed because we are accessing multiple instances of BulkActionsController
    allow_any_instance_of(BulkActionsController).to receive(:current_user)
      .and_return(current_user)
  end
  scenario 'New page has a populate druids div with last search' do
    expect_any_instance_of(CatalogController).to receive(:current_user)
      .at_least(:once).and_return(current_user)
    visit catalog_index_path q: 'stanford'
    click_link 'Bulk Actions'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    click_link 'New Bulk Action'
    expect(page).to have_css 'h1', text: 'New Bulk Action'
    expect(page).to have_css 'a[data-populate-druids="/catalog?action=index&' \
      'controller=catalog&pids_only=true&q=stanford"]'
  end
  scenario 'Populate druids from last search' do
    pending 'not implemented spec due to js testing restrictions'
    fail
  end
  scenario 'Creates a new jobs' do
    visit new_bulk_action_path
    choose 'bulk_action_action_type_descmetadatadownloadjob'
    fill_in 'pids', with: 'druid:br481xz7820'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'DescmetadataDownloadJob'
      expect(page).to have_css 'td', text: 'Scheduled Action'
    end
  end
end