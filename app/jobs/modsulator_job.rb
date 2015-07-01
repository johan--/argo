class ModsulatorJob < ActiveJob::Base
  queue_as :default

  TIME_FORMAT = "%Y-%m-%d %H:%M%P"

  def perform(uploaded_filename, output_directory, user_login, filetype, xml_only, note)
    original_filename = File.basename(uploaded_filename)

    if(!File.directory?(output_directory))
      FileUtils.mkdir_p(output_directory)
    end

    # This log will be used for generating the table of past jobs later
    log_filename = File.join(output_directory, Argo::Config.bulk_metadata_log)
    File.open(log_filename, 'w') { |log|
      start_timestamp = Time.now.strftime(TIME_FORMAT)
      log.puts("job_start #{start_timestamp}")
      log.puts("current_user #{user_login}")
      log.puts("input_file #{original_filename}")

      # Call the MODSulator web service to process the uploaded file. If a request fails, the job will fail
      # and automatically be retried, so we do not separately retry the HTTP request.
      response_xml = nil
      if(filetype == "xml")    # Just clean up the given XML file
        response_xml = RestClient.post(Argo::Config.urls.normalizer, :file => File.new(uploaded_filename, 'rb'), :filename => original_filename)
      else                               # The given file is a spreadsheet
        response_xml = RestClient.post(Argo::Config.urls.modsulator, :file => File.new(uploaded_filename, 'rb'), :filename => original_filename)
      end

      record_count = response_xml.scan('<xmlDoc id').size
      File.open(File.join(output_directory, 'metadata.xml'), "w") { |f| f.write(response_xml) }
      log.puts("xml_written #{Time.now.strftime(TIME_FORMAT)}")
      log.puts("records #{record_count}")
      
      if(note)
        log.puts("note #{note}")
      end

      unless xml_only
        # Load into DOR
      end

      finish_timestamp = Time.now.strftime(TIME_FORMAT)
      log.puts("job_finish #{finish_timestamp}")
    }

    # Remove the (temporary) uploaded file
    FileUtils.rm(uploaded_filename, :force => true)
  end
end