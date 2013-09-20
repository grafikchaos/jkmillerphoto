module ApplicationHelper

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  class HTMLwithPygments < Redcarpet::Render::HTML
    def block_code(code, language)
      sha = Digest::SHA1.hexdigest(code)
      Rails.cache.fetch ["code", language, sha].join('-') do
        Pygments.highlight(code, lexer: language)
      end
    end
  end

  def markdown(text)
    renderer = HTMLwithPygments.new(hard_wrap: true, filter_html: true)
    options = {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_html_blocks: true,
      strikethrough: true,
      superscript: true
    }
    Redcarpet::Markdown.new(renderer, options).render(text).html_safe if text.present?
  end

  def title(page_title)
    content_for(:title) { page_title.to_s.html_safe }
  end

  def main_action(action)
    content_for(:main_action) { action }
  end


  def close_alert_link
    link_to "&times;".html_safe, "#", :class => 'close', :data => { :dismiss => 'alert' }
  end

  def format_date(date, format = "%B %e, %Y")
    date = date.to_date if date.is_a?(String)
    date.try(:strftime, format)
  end

  def yes_no(value)
    case true
    when value.is_a?(String)
      bool_string = value.downcase == 't' ? 'Yes' : 'No'
    when value == true then bool_string = 'Yes'
    when value == false then bool_string = 'No'
    else
      bool_string = value
    end

    bool_string
  end


  # == Javascript
  #
  # view helper to add any necessary JS files to the
  # header placed in the yield(:head) in the layouts
  def load_javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  # == CSS
  #
  # view helper to add any necessary CSS files to the
  # header placed in the yield(:head) in the layouts
  def load_css(*files)
    content_for(:head) { stylesheet_link_tag(*files) }
  end

  # == back_link_to
  #
  # return a link that goes back to the desired resource's route
  # (typically will be the index action)
  #
  # Additional CanCan permissions check to see if the current_user has access
  # to go back to the previous page
  def back_link_to(resource, *args)
    link = ''.html_safe

    object  = determine_proper_resource(resource)
    options = args.first || {}

    # CSS classes for this crud link
    crud_link_css(options, 'back')
    # text to be displayed
    link_text = crud_link_text(options, 'back')

    # (optional) add a tooltip to the link
    if options.keys.include?(:tooltip)
      add_tooltip(options)
    end

    if defined? CanCan
      link += link_to link_text, url_for(resource), options if can?(:read, object)
    else
      link += link_to link_text, url_for(resource), options
    end

    link
  end

  # == default_crud_actions
  #
  # display the common CRUD actions (View, Edit, Delete)
  def default_crud_actions(resource, options = {})
    options = {
      use_button_group: true,
      button_group_class: "btn-group",
      except: []
    }.merge(options)

    links = ''.html_safe

    if options.keys.include?(:class)
      options[:class] += ' btn-default btn-xs '
    else
      options[:class] = 'btn-default btn-xs '
    end

    links << view_link(resource, options) unless options[:except].include?(:show)
    links << edit_link(resource, options) unless options[:except].include?(:edit)
    links << destroy_link(resource, options) unless options[:except].include?(:delete)

    if options[:use_button_group] == true
      content_tag(:div, links.html_safe, :class => "#{options[:button_group_class]}")
    else
      links
    end
  end

  # == create_link
  #
  # check if the current_user can create the resource and return a link (or not)
  def create_link(resource, *args)
    link = ''.html_safe

    resource_name = normalized_resource_name(resource)
    object        = determine_proper_resource(resource)
    options       = args.first || {}

    # CSS classes for this crud link
    crud_link_css(options, 'create')
    # text to be displayed
    link_text = crud_link_text(options, 'create')

    # (optional) add a tooltip to the link
    if options.keys.include?(:tooltip)
      add_tooltip(options)
    end


    if defined? CanCan
      link += link_to link_text, url_for(resource), options if can?(:create, object)
    else
      link += link_to link_text, url_for(resource), options
    end

    link
  end

  # == view_link
  #
  # check if the current_user can view a resource and return a link (or not)
  def view_link(resource, *args)
    link = ''.html_safe

    resource_name = normalized_resource_name(resource)
    object        = determine_proper_resource(resource)
    options       = args.first || {}

    # CSS classes for this crud link
    crud_link_css(options, 'view')
    # text to be displayed
    link_text = crud_link_text(options, 'view')

    # (optional) add a tooltip to the link
    if options.keys.include?(:tooltip)
      add_tooltip(options)
    end

    options[:id]    = 'view-' + link_id(object)
    options[:title] = 'View this ' + resource_name

    if defined? CanCan
      link += link_to link_text, url_for(resource), options if can?(:read, object)
    else
      link += link_to link_text, url_for(resource), options
    end

    link
  end

  # == edit_link
  #
  # check if the current_user can edit a resource and return a link (or not)
  def edit_link(resource, *args)
    link = ''.html_safe

    resource_name = normalized_resource_name(resource)
    object        = determine_proper_resource(resource)
    options       = args.first || {}

    # CSS classes for this crud link
    crud_link_css(options, 'edit')
    # text to be displayed
    link_text = crud_link_text(options, 'edit')

    # (optional) add a tooltip to the link
    if options.keys.include?(:tooltip)
      add_tooltip(options)
    end

    options[:id]    = 'edit-' + link_id(object)
    options[:title] = 'Edit this ' + resource_name

    case true
    when defined? CanCan
      if resource.is_a?(Array)
        # check if we can access directly via a shallow route
        begin
          if url_for([:edit, object])
            link += link_to link_text, url_for([:edit, object]), options if can?(:edit, object)
          else
            link += link_to link_text, url_for(resource.unshift(:edit)), options if can?(:edit, object)
          end
        rescue Exception => e
          link += link_to link_text, url_for(resource.unshift(:edit)), options if can?(:edit, object)
        end
      else
        link += link_to link_text, url_for([:edit, resource]), options if can?(:edit, object)
      end
    else
      if resource.is_a?(Array)
        # check if we can access directly via a shallow route
        begin
          if url_for([:edit, object])
            link += link_to link_text, url_for([:edit, object]), options
          else
            link += link_to link_text, url_for(resource.unshift(:edit)), options
          end
        rescue Exception => e
          link += link_to link_text, url_for(resource.unshift(:edit)), options
        end
      else
        link += link_to link_text, url_for([:edit, resource]), options
      end
    end

    link
  end

  # == destroy_link
  #
  # check to see if the current_user can delete a resource and return a link (or not)
  def destroy_link(resource, *args)
    link = ''.html_safe

    resource_name = normalized_resource_name(resource)
    object        = determine_proper_resource(resource)
    options       = args.first || {}

    # CSS classes for this crud link
    crud_link_css(options, 'destroy')
    # text to be displayed
    link_text = crud_link_text(options, 'destroy')

    # (optional) add a tooltip to the link
    if options.keys.include?(:tooltip)
      add_tooltip(options)
    end

    options[:id]      = 'delete-' + link_id(object)
    options[:title]   = 'Delete this ' + resource_name
    options[:confirm] = "Are you sure you want to delete this #{resource_name}? This may not be recoverable once destroyed."
    options[:method]  = :delete
    options[:data]    = {
      confirm_fade: true,
      confirm_title: options[:title],
      confirm_cancel: 'Cancel',
      confirm_proceed: 'Got it. Proceed.',
      confirm_proceed_class: 'btn-danger'
    }

    if resource.is_a?(Array) && resource.include?(:edit)
      resource.delete(:edit)
    end

    if defined? CanCan
      # check if we can access directly via a shallow route
      begin
        if url_for([:destroy, object])
          link += link_to link_text, url_for([:destroy, object]), options if can?(:destroy, object)
        else
          link += link_to link_text, url_for(resource), options
        end
      rescue Exception => e
        link += link_to link_text, url_for(resource), options if can?(:destroy, object)
      end
    else
      # check if we can access directly via a shallow route
      begin
        if url_for([:destroy, object])
          link += link_to link_text, url_for([:destroy, object]), options
        else
          link += link_to link_text, url_for(resource), options
        end
      rescue Exception => e
        link += link_to link_text, url_for(resource), options
      end
    end

    link
  end
  alias_method :delete_link, :destroy_link

  # == crud_link_css
  #
  # utility method to help standardize a link's css classes
  # for the common CRUD actions
  #
  # @param  hash           options
  # @param  string|symbol  action
  # @return hash
  def crud_link_css(options, action)

    if options.keys.include?(:icon_only) && options[:icon_only] == true
        if options.keys.include?(:class)
          options[:class] += "#{action.to_s.downcase}-link "
        else
          options[:class] = "#{action.to_s.downcase}-link "
        end
    else
      if options.keys.include?(:class)
        options[:class].insert(0, "#{action.to_s.downcase}-link btn ")
      else
        options[:class] = "#{action.to_s.downcase}-link btn"
      end

      case true
      when %w(delete destroy).include?(action.to_s.downcase) then options[:class] += ' btn-danger'
      end
    end

    options
  end

  # == crud_link_text
  #
  # utility method to help standardize link text (including icons)
  # for the common CRUD actions
  #
  # @param  hash           options
  # @param  string|symbol  action
  # @return string
  def crud_link_text(options, action)
    action_str = action.to_s.downcase

    # match the action to an icon
    bootstrap_icon = crud_link_icon(action, options)

    if bootstrap_icon.present?
      icon = "<i class='#{bootstrap_icon}'></i>"
    else
      icon = ''
    end

    # default link text for common CRUD actions/aliases
    case true
    when %w(new create).include?(action_str) then default_link_text = 'Add'
    when %w(update edit).include?(action_str) then default_link_text = 'Edit'
    when %w(show view).include?(action_str) then default_link_text = 'View'
    when %w(delete destroy).include?(action_str) then default_link_text = 'Delete'
    when %w(back).include?(action_str) then default_link_text = 'Back'
    end

    # Use the options link_text value if it exists;
    # otherwise use our link_text determined by the action name
    if options.keys.include?(:link_text)
      link_text = "#{icon} #{options[:link_text]}".html_safe
    else
      link_text = "#{icon} #{default_link_text}".html_safe
    end

    link_text
  end

  # == crud_link_icon
  #
  # determine which bootstrip_icon should be used for the action
  #
  # @param  string|symbol  action
  # @return string
  def crud_link_icon(action, options)
    action_str = action.to_s.downcase

    case true
    when %w(new create).include?(action_str) then bootstrap_icon = 'icon-plus'
    when %w(update edit).include?(action_str) then bootstrap_icon = 'icon-pencil'
    when %w(show view).include?(action_str) then bootstrap_icon = 'icon-eye-open'
    when %w(delete destroy).include?(action_str) then bootstrap_icon = 'icon-trash'
    when %w(back).include?(action_str) then bootstrap_icon = 'icon-chevron-left'
    else bootstrap_icon = ''
    end

    bootstrap_icon
  end


  # == add_tooltip
  #
  # utility method to standardize and add
  # necessary html data attributes to an element
  #
  # @param  hash           options
  # @param  string|symbol  action
  # @return hash
  def add_tooltip(options)
    if options.keys.include?(:tooltip)
      options[:rel] = 'tooltip'

      # tooltip class
      if options.keys.include?(:tooltip_class)
        options[:class] += " #{options[:tooltip_class]}"
      else
        options[:class] += ' tooltipped'
      end

      # placement of the tooltip
      if options.keys.include?(:tooltip_placement)
        options['data-placement'] = options[:tooltip_placement]
      else
        options['data-placement'] = 'top'
      end
    end

    options
  end

  def link_id(resource)
    if resource.present?
      if resource.respond_to?('friendly_id') && resource.slug.present?
        resource.slug
      elsif resource.respond_to?('username')
        resource.username.downcase
      elsif resource.respond_to?('name') && resource.name.present?
        resource.name.parameterize('_')
      else
        normalized_name = normalized_resource_name(resource)
        normalized_name +  "-" + resource.id.to_s
      end
    end
  end

  def normalized_resource_name(resource)
    resource_name = ''

    case true
    when resource.is_a?(Array)
      last_resource_name = resource.last

      if last_resource_name.is_a?(Symbol)
        resource_name += last_resource_name.to_s.titleize
      else
        resource_name += last_resource_name.class.to_s.titleize
      end

    when resource.is_a?(Symbol)
      resource_name += resource.to_s.titleize

    else
      resource_name += resource.class.to_s.titleize
    end

    resource_name
  end

  def determine_proper_resource(resource)
    if resource.is_a?(Array)
      obj = resource.last
    else
      obj = resource
    end
    obj
  end


end
