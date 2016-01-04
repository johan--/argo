require 'spec_helper'

RSpec.describe 'items/close_version_ui.js.erb' do
  it 'renders the JS template' do
    stub_template 'items/_close_version_ui.js.erb' => 'stubbed_closed_version'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Close version'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_closed_version'
  end
end
