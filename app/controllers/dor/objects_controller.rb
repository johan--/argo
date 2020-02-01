# frozen_string_literal: true

class Dor::ObjectsController < ApplicationController
  include ApplicationHelper # for fedora_base
  before_action :munge_parameters

  def create
    if params[:collection] && params[:collection].length == 0
      params.delete :collection
    end

    begin
      response = Dor::Services::Client.objects.register(params: registration_params.to_h)
    rescue Dor::Services::Client::UnexpectedResponse => e
      return render plain: e.message, status: :conflict if e.message.start_with?('Conflict')

      return render plain: e.message, status: :bad_request
    end

    pid = response[:pid]

    Dor::Config.workflow.client.create_workflow_by_name(pid, params[:workflow_id], version: '1')

    respond_to do |format|
      format.json { render json: response, location: object_location(pid) }
      format.xml  { render xml: response, location: object_location(pid) }
      format.text { render plain: pid, location: object_location(pid) }
      format.html { redirect_to object_location(pid) }
    end
  end

  private

  # source_id and label are required parameters
  def registration_params
    hash = params.permit(:object_type, :admin_policy, :metadata_source, :rights,
                         :collection, :other_id, tag: [], seed_datastream: [])
    hash[:source_id] = params.require(:source_id)
    hash[:label] = params.require(:label)
    hash
  end

  def munge_parameters
    case request.content_type
    when 'application/xml', 'text/xml'
      merge_params(Hash.from_xml(request.body.read))
    when 'application/json', 'text/json'
      merge_params(JSON.parse(request.body.read))
    end
  end

  def merge_params(hash)
    # convert camelCase parameter names to under_score, and string keys to symbols
    # e.g., 'objectType' to :object_type
    hash.each_pair do |k, v|
      key = k.underscore
      params[key.to_sym] = v
    end
  end

  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end
end
