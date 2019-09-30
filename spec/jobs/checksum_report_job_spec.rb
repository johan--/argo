# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChecksumReportJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:output_directory) { 'tmp/checksum_report_job_success' }
  # so 'fail' tests don't fail due to CSV from 'success' tests
  let(:output_directory_fail) { 'tmp/checksum_report_job_fail' }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'ChecksumReportJob',
      log_name: 'tmp/checksum_report_job_log.txt'
    )
  end
  let(:csv_response) { "druid:123,checksum1,checksum2\ndruid:456,checksum3,checksum4\n" }
  let(:log_buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Ability).to receive(:new).and_return(ability)
  end

  describe '#perform_now' do
    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }

      context 'happy path' do
        before do
          allow(Preservation::Client.objects).to receive(:checksums).with(druids: pids).and_return(csv_response)
        end

        it 'calls the presevation_catalog API, writes a CSV file, and records success counts' do
          subject.perform(bulk_action.id,
                          output_directory: output_directory,
                          pids: pids,
                          groups: groups,
                          user: user)
          expect(Preservation::Client.objects).to have_received(:checksums).with(druids: pids)
          expect(File).to exist(File.join(output_directory, Settings.checksum_report_job.csv_filename))
          expect(bulk_action.druid_count_total).to eq(pids.length)
          expect(bulk_action.druid_count_fail).to eq(0)
          expect(bulk_action.druid_count_success).to eq(pids.length)
        end
      end

      context 'Preservation::Client throws error' do
        before do
          allow(Preservation::Client.objects).to receive(:checksums).with(druids: pids).and_raise(Preservation::Client::UnexpectedResponseError, 'ruh roh')
        end

        it 'calls the presevation_catalog API, does not write a CSV file, and records failure counts' do
          subject.perform(bulk_action.id,
                          output_directory: output_directory_fail,
                          pids: pids,
                          groups: groups,
                          user: user)
          expect(Preservation::Client.objects).to have_received(:checksums).with(druids: pids)
          expect(File).not_to exist(File.join(output_directory_fail, Settings.checksum_report_job.csv_filename))
          expect(bulk_action.druid_count_total).to eq(pids.length)
          expect(bulk_action.druid_count_fail).to eq(pids.length)
          expect(bulk_action.druid_count_success).to eq(0)
        end
      end
    end

    context 'without authorization' do
      let(:ability) { instance_double(Ability, can?: false) }

      before do
        allow(Preservation::Client.objects).to receive(:checksums)
      end

      it 'does not call the presevation_catalog API, does not write a CSV file, and records failure counts' do
        expect {
          subject.perform(bulk_action.id,
                          output_directory: output_directory_fail,
                          pids: pids,
                          groups: groups,
                          user: user)
        }.to raise_error(RuntimeError, /ChecksumReportJob not authorized to view all content/)
        expect(Preservation::Client.objects).not_to have_received(:checksums)
        expect(File).not_to exist(File.join(output_directory_fail, Settings.checksum_report_job.csv_filename))
        expect(bulk_action.druid_count_total).to eq(pids.length)
        expect(bulk_action.druid_count_fail).to eq(pids.length)
        expect(bulk_action.druid_count_success).to eq(0)
      end
    end
  end
end