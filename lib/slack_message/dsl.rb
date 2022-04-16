class SlackMessage::Dsl
  attr_reader :body, :default_section, :custom_bot_name, :custom_bot_icon, :profile
  attr_accessor :custom_notification

  EMSPACE = " " # unicode emspace, Slack won't compress this

  def initialize(block, profile)
    # Delegate missing methods to caller scope. Thanks 2008:
    # https://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
    @caller_self = eval("self", block.binding)

    @body             = []
    @profile          = profile
    @default_section  = Section.new(self)

    @custom_bot_name      = nil
    @custom_bot_icon      = nil
    @custom_notification  = nil
  end

  # allowable top-level entities within a block

  def section(&block)
    finalize_default_section

    section = Section.new(self).tap do |s|
      s.instance_eval(&block)
    end

    @body.push(section.render)
  end

  def divider
    finalize_default_section

    @body.push({ type: "divider" })
  end

  def image(url, alt_text:, title: nil)
    finalize_default_section

    config = {
      type: "image",
      image_url: url,
      alt_text: alt_text,
    }

    if !title.nil?
      config[:title] = {
        type: "plain_text", text: title, emoji: true
      }
    end

    @body.push(config)
  end

  def context(text)
    finalize_default_section

    if text == "" || text.nil?
      raise ArgumentError, "Cannot create a context block without a value."
    end

    text = self.enrich_text(text)


    previous_context = @body.find { |element| element[:type] && element[:type] == "context" }
    if previous_context
      previous_text = previous_context[:elements].first[:text]
      warn "WARNING: Overriding previous context in section: #{previous_text}"
    end

    @body.push({ type: "context", elements: [{
      type: "mrkdwn", text: text
    }]})
  end

  # end entities

  # delegation to allow terse syntax without e.g. `section`

  def text(*args); default_section.text(*args); end
  def link_button(*args); default_section.link_button(*args); end
  def accessory_image(*args); default_section.accessory_image(*args); end
  def blank_line(*args); default_section.blank_line(*args); end
  def link(*args); default_section.link(*args); end
  def list_item(*args); default_section.list_item(*args); end
  def ul(*args); default_section.ul(*args); end
  def ol(*args); default_section.ol(*args); end

  # end delegation

  # bot / notification overrides

  def bot_name(name)
    @custom_bot_name = name
  end

  def bot_icon(icon)
    @custom_bot_icon = icon
  end

  def notification_text(msg)
    if @custom_notification
      warn "WARNING: Overriding previous custom notification text: #{@custom_notification}"
    end

    @custom_notification = msg
  end

  # end bot name

  def render
    finalize_default_section
    @body
  end

  def method_missing(meth, *args, &blk)
    @caller_self.send meth, *args, &blk
  end

  # replace emails w/ real user IDs
  def enrich_text(text_body)
    text_body.scan(SlackMessage::EMAIL_TAG_PATTERN).each do |email_tag|
      begin
        raw_email = email_tag.gsub(/[><]/, '')
        user_id   = SlackMessage::Api::user_id_for(raw_email, profile)

        text_body.gsub!(email_tag, "<@#{user_id}>") if user_id
      rescue SlackMessage::ApiError => e
        # swallow errors for not-found users
      end
    end

    text_body
  end

  private

  # when doing things that would generate new top-levels, first try
  # to finish the implicit section.
  def finalize_default_section
    if default_section.has_content?
      @body.push(default_section.render)
    end

    @default_section = Section.new(self)
  end

  class Section
    attr_reader :body

    def initialize(parent)
      @parent = parent
      @body = { type: "section" }
      @list = List.new
    end

    def text(msg)
      if msg == "" || msg.nil?
        raise ArgumentError, "Cannot create a text node without a value."
      end

      msg = @parent.enrich_text(msg)

      if @body.include?(:text)
        @body[:text][:text] << "\n#{msg}"

      else
        @body.merge!({ text: { type: "mrkdwn", text: msg } })
      end
    end

    def ul(elements)
      raise ArgumentError, "Please pass an array when creating a ul." unless elements.respond_to?(:map)

      msg = elements.map { |text| "#{EMSPACE}• #{text}" }.join("\n")
      msg = @parent.enrich_text(msg)

      text(msg)
    end

    def ol(elements)
      raise ArgumentError, "Please pass an array when creating an ol." unless elements.respond_to?(:map)

      msg = elements.map.with_index(1) { |text, idx| "#{EMSPACE}#{idx}. #{text}" }.join("\n")
      msg = @parent.enrich_text(msg)

      text(msg)
    end

    # styles:  default, primary, danger
    def link_button(label, target, style: :primary)
      if !@body[:accessory].nil?
        previous_type = @body[:accessory][:type]
        warn "WARNING: Overriding previous #{previous_type} in section to use link_button instead: #{label}"
      end

      unless /(^|\s)((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/i =~ target
        warn "WARNING: Passing a probably-invalid URL to link button #{label} (url: '#{target}')"
      end

      config = {
        accessory: {
          type: "button",
          url: target,
          text: {
            type: "plain_text",
            text: label,
            emoji: true
          },
        }
      }

      if style != :default
        config[:accessory][:style] = style
      end

      @body.merge!(config)
    end

    def accessory_image(url, alt_text: nil)
      if !@body[:accessory].nil?
        previous_type = @body[:accessory][:type]
        warn "WARNING: Overriding previous #{previous_type} in section to use accessory image instead: #{url}"
      end

      config = {
        accessory: {
          type: "image",
          image_url: url
        }
      }

      config[:accessory][:alt_text] = alt_text if !alt_text.nil?

      @body.merge!(config)
    end

    # for markdown links
    def link(label, target)
      "<#{target}|#{label}>"
    end

    def list_item(title, value)
      if value == "" || value.nil?
        raise ArgumentError, "Can't create a list item for '#{title}' without a value."
      end

      value = @parent.enrich_text(value)
      @list.add(title, value)
    end

    def blank_line
      text EMSPACE
    end

    def has_content?
      @body.keys.length > 1 || @list.any?
    end

    def render
      unless has_content?
        raise ArgumentError, "Can't create a section with no content."
      end

      body[:fields] = @list.render if @list.any?

      if body[:text] && body[:text][:text] && !@parent.custom_notification
        @parent.notification_text(body[:text][:text])
      end

      body
    end
  end

  class List
    def initialize
      @items = []
    end

    def any?
      @items.any?
    end

    def add(title, value)
      @items.push(["*#{title}*", value])
    end

    def render
      @items.push([' ', ' ']) if @items.length % 2 == 1
      @items.each_slice(2).flat_map do |(first, second)|
        [
          { type: "mrkdwn", text: first[0] },
          { type: "mrkdwn", text: second[0] },
          { type: "mrkdwn", text: first[1] },
          { type: "mrkdwn", text: second[1] },
      ]
      end
    end
  end
end
