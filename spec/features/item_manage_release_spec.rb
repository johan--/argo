require 'spec_helper'

RSpec.feature 'Item manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  before(:each) do
    obj = double(
      'item',
      admin_policy_object: false,
      datastreams: {},
      can_manage_item?: true,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
    allow(current_user).to receive(:is_admin?).and_return true
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(current_user)
    allow(Dor).to receive(:find).and_return(obj)
  end
  let(:druid) { 'druid:qq613vj0238' }
  scenario 'Has a manage release button' do
    visit catalog_path(druid)
    expect(page).to have_css 'a', text: 'Manage release'
  end
  scenario 'Creates a new bulk action' do
    visit manage_release_path(druid)
    expect(page).to have_css 'label', text: "Manage release to discovery applications for item #{druid}"
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: 'Scheduled Action'
    end
  end
end