/*
  usage:  
    if you want to have a link load the contents of the link target in a persistent modal, add the attribute 'data-behavior="persistent-modal"'.
    e.g.:
      <a title="DC" data-behavior="persistent-modal" href="/view/druid:dy196vh8233/ds/DC">DC</a>
    or, if you're building a link from ruby, something like:
      link_to specs[:dsid], ds_aspect_view_catalog_path(doc['id'], specs[:dsid]), :title => specs[:dsid], :data => { behavior: 'persistent-modal' }

  the modal is persistent in that subsequent invocations of the modal on the same overall page load will load the same retained 
  contents of the modal from the initial load, unless the modal was specifically closed using the "cancel" button.  useful if for
  things like forms or datastream editing text areas, where a user might want to close the modal without losing their partial input.

  like the argo's customization of the regular blacklight modal (itself a customization of the bootstrap modal), this modal will not close
  when the user hits escape or clicks outside the modal.  it will only close if the user hits the close "x" in the title bar or the "cancel" 
  button (which will also remove it from the DOM and force a reload if that same modal is hit again).

  the modal title is pulled from the link text.

  ripped off from parts of:
    https://github.com/sul-dlss/SearchWorks/blob/2bef864ba859048ab9761d00bc7688700ea9faaf/app/assets/javascripts/jquery.requestsModal.js
    https://github.com/projectblacklight/blacklight/blob/v5.9.4/app/assets/javascripts/blacklight/ajax_modal.js
*/
(function($){
  $.fn.persistentModal = function() {

    return this.each(function(){
      var $modalLink = $(this);
      var linkTarget = $modalLink.attr('href');
      var linkText = $modalLink.text();
      init();

      function init(){
        $modalLink.on('click', function(e){
          e.preventDefault();
          toggleOrCreateModal();
        });
      }

      function toggleOrCreateModal() {
        if (!modalIsPresent()) {
          createModal();
        }
        showModal();
      }

      function showModal() {
        $('div.persistent-modal').modal('hide');
        modalForTarget().modal('show');
      }

      function receiveAjax(data) {      
        //default to error text, replace if we got something back
        var contents = "Error retrieving content";
        if (data.readyState != 0) {
          contents = data;
        }

        // does it have a data- selector for container?  if so, just use the contents of that container
        // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/master/src/ajax/load.js?source=c#L62
        var container =  $("<div>").
          append( contents ).find( Blacklight.ajaxModal.containerSelector ).first();
        if (container.size() !== 0) {
          contents = container.html();
        }

        $('body').append(persistentModalHtml(contents));
        modalForTarget().find('.modal-title').text(linkText);
        modalForTarget().find('[data-behavior="persistent-modal"]').persistentModal();
        applyModalCloseBehavior();
        showModal();
      }

      function createModal() {
        var jqxhr = $.ajax({
          url: linkTarget,
          dataType: 'text'
        });

        jqxhr.always( receiveAjax );
      }

      function applyModalCloseBehavior() {
        modalForTarget().find('[data-behavior="cancel-link"]').on('click', function() {
          modalForTarget().modal('hide');
          modalForTarget().remove();
        });
      }

      function modalForTarget() {
        return $('[data-persistent-modal-url="' + linkTarget + '"]');
      }

      function modalIsPresent() {
        return modalForTarget().length > 0;
      }

      function persistentModalHtml(modalBody) {
        modalHtml = [
          // the 'data-backdrop="static"' and 'data-keyboard="false"' attributes keep the modal from closing on clickaway or escape, respectively
          '<div class="modal persistent-modal" tabindex="-1" role="modal" data-persistent-modal-url="' + linkTarget + '" data-backdrop="static" data-keyboard="false">',
          '  <div class="modal-dialog">',
          '    <div class="modal-header">',
          '      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>',
          '      <h3 class="modal-title">TITLE</h3>',
          '    </div>',
          '    <div class="modal-content">',
          '      <div class="modal-body">',
          '        '+modalBody,
          '      </div>',
          '      <div class="form-group cancel-footer">',
          '        <button data-behavior="cancel-link" class="cancel-link btn btn-link">Cancel</button>',
          '      </div>',
          '    </div>',
          '  </div>',
          '</div>'
        ].join('\n');
        return modalHtml;
      }
    });
  };

})(jQuery);

Blacklight.onLoad(function() {
  $('[data-behavior="persistent-modal"]').persistentModal();
});