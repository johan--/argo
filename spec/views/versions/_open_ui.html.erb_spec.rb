# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'versions/_open_ui.html.erb' do
  let(:object) { double('object', pid: 'druid:abc123') }

  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered).to have_css '.form-group label', text: 'Type'
    expect(rendered).to have_css '.form-group select#significance.form-control'
    expect(rendered)
      .to have_css '.form-group label', text: 'Version description'
    expect(rendered).to have_css '.form-group textarea#description.form-control'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Open Version'
  end
end
