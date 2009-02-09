require 'net/smtp'
require 'time'

class BlockMail
  def initialize(host, port=25, &block)
    @smtp = Net::SMTP.start(host, port)
    block.call(self)
    @smtp.finish
  end

  def message(encoding='us-ascii', &block)
    msg = BlockMail::Message.new(encoding, &block)
    @smtp.send_mail *msg.to_smtp
  end

  class Message
    def self.encode(val, encoding)
      if val.ascii_only?
        val
      else
        '=?%s?b?%s?=' % [
          encoding,
          [val.encode(encoding)].pack('m').split.join
        ]
      end
    end

    def initialize(encoding, &block)
      @encoding = encoding

      @subject = ''
      @from    = []
      @to      = []
      @body    = ''

      block.call(self) if block_given?
    end

    def encode(val)
      self.class.encode(val, @encoding)
    end

    def encode_addr(addr, name=nil)
      if name
        '%s <%s>' % [encode(name), addr]
      else
        '<%s>' % addr
      end
    end

    def subject(val)
      @subject = val
    end

    def from(addr, name=nil)
      @from = [addr, name]
    end

    def to(addr, name=nil)
      @to << [addr, name]
    end

    def body(val)
      @body = val
    end

    def to_s
      ([
        'MIME-Version: 1.0',
        'Content-Type: text/plain; charset=' + @encoding,
        'From: ' + encode_addr(@from[0], @from[1]),
        @to.map do |val|
          'To: ' + encode_addr(val[0], val[1])
        end,
        'Date: ' + Time.now.rfc2822,
        'Subject: ' + encode(@subject)
      ].join("\n") + "\n\n" + @body).encode(@encoding)
    end

    def to_smtp
      [to_s.force_encoding('ASCII-8BIT'), @from[0], *@to.map do |v| v[0] end]
    end
  end
end
