require 'rails_helper'

RSpec.describe BankParser, type: :lib do
  let(:fixture_folder) { 'spec/fixtures' }
  
  subject do
    BankParser.new.parse(raw_xml)
  end

  context 'Banking Data 1' do
    let(:raw_xml) { File.read(Rails.root.join(fixture_folder, "banking_data_1.xml")) }
    let(:output_file) { Rails.root.join(fixture_folder, 'banking_data_1_result.yml') }
    
    it do
      stored_result = YAML.unsafe_load(File.read(output_file))
      expect(subject).to eq(stored_result)
    end
  end

  context 'Banking Data 2' do
    let(:raw_xml) { File.read(Rails.root.join(fixture_folder, "banking_data_2.xml")) }
    let(:output_file) { Rails.root.join(fixture_folder, 'banking_data_2_result.yml') }
    
    it do
      stored_result = YAML.unsafe_load(File.read(output_file))
      expect(subject).to eq(stored_result)
    end
  end
end