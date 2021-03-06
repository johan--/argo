# frozen_string_literal: true

# Updates the metadata of an object with the given MODS
class ApplyModsMetadata
  # @param [String] apo_druid
  # @param [Nokogiri::XML::Element] mods_node A MODS XML node.
  # @param [Dor::Item] item the item to be updated
  # @param [String] original_filename the filename these updates came from
  # @param [Ability] ability the abilities of the acting user
  # @param [#puts] log
  def initialize(apo_druid:, mods_node:, item:, original_filename:, ability:, log:)
    @apo_druid = apo_druid
    @mods_node = mods_node
    @item = item
    @original_filename = original_filename
    @ability = ability
    @log = log
  end

  def apply
    return unless item

    # Only update objects that are governed by the correct APO
    unless item.admin_policy_object_id == apo_druid
      log.puts("argo.bulk_metadata.bulk_log_apo_fail #{item.pid}")
      return
    end

    if in_accessioning?
      log.puts("argo.bulk_metadata.bulk_log_skipped_accession #{item.pid}")
      return
    end

    return unless status_ok?

    return unless ability.can? :manage_item, item

    # We only update objects if the descMetadata XML is different
    current_metadata = item.descMetadata.content
    if equivalent_nodes(Nokogiri::XML(current_metadata).root, mods_node)
      log.puts("argo.bulk_metadata.bulk_log_skipped_mods #{item.pid}")
      return
    end

    item.descMetadata.content = mods_node.to_s

    errors = ModsValidator.validate(item.descMetadata.ng_xml)
    if errors.present?
      log.puts "argo.bulk_metadata.bulk_log_validation_error #{item.pid} #{errors.join(';')}"
      return
    end

    version_object

    item.save!
    log.puts("argo.bulk_metadata.bulk_log_job_save_success #{item.pid}")
  rescue StandardError => e
    log_error!(e)
  end

  private

  attr_reader :apo_druid, :mods_node, :item, :original_filename, :ability, :log

  def item_druid
    item.pid
  end

  # Log the error
  def log_error!(exception)
    log.puts("argo.bulk_metadata.bulk_log_error_exception #{item.pid}")
    log.puts(exception.message.to_s)
    log.puts(exception.backtrace.to_s)
  end

  # Open a new version for the given object if it is in the accessioned state.
  def version_object
    return unless accessioned?

    unless DorObjectWorkflowStatus.new(item.pid, version: item.current_version).can_open_version?
      log.puts("argo.bulk_metadata.bulk_log_unable_to_version #{item.pid}") # totally unexpected
      return
    end
    commit_new_version
  end

  # Open a new version for the given object.
  def commit_new_version
    VersionService.open(identifier: item.pid,
                        significance: 'minor',
                        description: "Descriptive metadata upload from #{original_filename}",
                        opening_user_name: ability.current_user.sunetid)
  end

  # Check if two MODS XML nodes are equivalent.
  #
  # @param [Nokogiri::XML::Element] node1 A MODS XML node.
  # @param [Nokogiri::XML::Element] node2 A MODS XML node.
  # @return [Boolean] true if the given nodes are equivalent, false otherwise.
  def equivalent_nodes(node1, node2)
    EquivalentXml.equivalent?(node1,
                              node2,
                              element_order: false,
                              normalize_whitespace: true,
                              ignore_attr_values: ['version', 'xmlns', 'xmlns:xsi', 'schemaLocation'])
  end

  # Returns true if the given object is accessioned, false otherwise.
  def accessioned?
    (6..8).cover?(status)
  end

  # Checks whether or not a DOR object is in accessioning or not.
  #
  # @return [Boolean] true if the object is currently being accessioned, false otherwise
  def in_accessioning?
    (2..5).cover?(status)
  end

  # Checks whether or not a DOR object's status is OK for a descMetadata update. Basically, the only times we are
  # not OK to update is if the object is currently being accessioned and if the object has status unknown.
  #
  # @return [Boolean] true if the object's status allows us to update the descMetadata datastream, false otherwise
  def status_ok?
    [1, 6, 7, 8, 9].include?(status)
  end

  # Returns the status code for a DOR object
  #
  # @return [Integer] value corresponding to the status info list
  def status
    @status ||= WorkflowClientFactory.build.status(druid: item.pid, version: item.current_version).info[:status_code]
  end
end
