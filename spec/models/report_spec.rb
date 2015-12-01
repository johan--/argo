require 'spec_helper'

describe Report, :type => :model do
  context 'csv' do
    before :each do
      @csv = subject.to_csv
    end

    it 'should generate data in valid CSV format' do
      expect { CSV.parse(@csv) }.not_to raise_error
    end

    it 'should generate many rows of data' do
      rows = CSV.parse(@csv)
      expect(rows.is_a?(Array)).to be_truthy
      expect(rows.length).to be > 1    # at least headers + data
      expect(rows[0].length).to eq(24) # default headers
    end

    it 'should force double quotes for all fields' do
      expect(@csv[0]).to eq('"')
    end

    it 'should handle a title with double quotes in it' do
      row = CSV.parse(@csv).find { |row| row[0] == 'hj185vb7593' }
      expect(row[2]).to eq('Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
    end

    it 'should handle a multivalued fields' do
      row = CSV.parse(@csv).find { |row| row[0] == 'xb482bw3979' }
      expect(row[11].split('; ').length).to eq(2)
    end
  end
end