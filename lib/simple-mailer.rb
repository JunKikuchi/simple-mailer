require 'time'

class SimpleMailer
  def self.parse(message)
  end

  class SMTP
    def initialize(params={}, &block)
      require 'net/smtp'
      @params = {
        :host => 'localhost',
        :port => 25
      }.merge(params)

      @smtp = Net::SMTP.start(@params[:host], @params[:port].to_i)
      block.call(self)
      @smtp.finish
    end

    def message(params={}, &block)
      @params = {
        :encoding => 'us-ascii'
      }.merge(params)

      @smtp.send_mail(
        *Message.new(@params[:encoding], &block).to_smtp
      )
    end
  end

  class Message
    if RUBY_VERSION < '1.9'
      require 'nkf'

      ENCODING = {
        'iso-2022-jp' => proc do |val|
          NKF.nkf '--jis', val
        end
      }

      def self.encode(val, encoding)
        ENCODING[encoding.downcase].call(val)
      end

      def self.encode_header(val, encoding)
        '=?%s?b?%s?=' % [
          encoding,
          [self.encode(val, encoding)].pack('m').split.join
        ]
      end
    else
      def self.encode(val, encoding)
        val.encode(encoding)
      end

      def self.encode_header(val, encoding)
        if val.ascii_only?
          val
        else
          '=?%s?b?%s?=' % [
            encoding,
            [val.encode(encoding)].pack('m').split.join
          ]
        end
      end
    end

    def initialize(encoding, &block)
      @encoding = encoding

      @from    = []
      @to      = []
      @cc      = []
      @bcc     = []
      @subject = ''
      @body    = ''

      block.call(self)
    end

    def encode_header(val)
      self.class.encode_header(val, @encoding)
    end

    def encode(val)
      self.class.encode(val, @encoding)
    end

    def encode_addr(addr, name=nil)
      if name
        '%s <%s>' % [encode_header(name), addr]
      else
        '<%s>' % addr
      end
    end

    def from(addr, name=nil)
      @from = [addr, name]
    end

    def to(addr, name=nil)
      @to << [addr, name]
    end

    def cc(addr, name=nil)
      @cc << [addr, name]
    end

    def bcc(addr, name=nil)
      @bcc << [addr, name]
    end

    def subject(subject)
      @subject = subject
    end

    def body(body)
      @body = body
    end

    def to_s
      ([
        'MIME-Version: 1.0',
        'Content-Type: text/plain; charset=' + @encoding,
        'From: ' << encode_addr(@from[0], @from[1]),
        @to.map do |val|
          'To: ' << encode_addr(val[0], val[1])
        end,
        @cc.map do |val|
          'Cc: ' << encode_addr(val[0], val[1])
        end,
        'Date: ' << Time.now.rfc2822,
        'Subject: ' << encode_header(@subject)
      ].flatten!.join("\n") + "\n\n" + encode(@body))
    end

    def to_smtp
      [
        if RUBY_VERSION < '1.9'
          to_s
        else
          to_s.force_encoding('ASCII-8BIT')
        end,
        @from[0],
        *((@to + @cc + @bcc).map do |v| v[0] end)
      ]
    end
  end
end
