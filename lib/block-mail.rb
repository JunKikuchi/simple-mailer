require 'time'

class BlockMail
  def self.parse(message)
  end

  class SMTP
    def initialize(host, port=25, &block)
      require 'net/smtp'

      @smtp = Net::SMTP.start(host, port)
      block.call self
      @smtp.finish
    end

    def message(encoding='us-ascii', &block)
      @smtp.send_mail *BlockMail::Message.new(encoding, &block).to_smtp
    end
  end

  class POP3
    def initialize(user, pass, host, port=110, &block)
      require 'net/pop'

      @pop = Net::POP.start(host, port, user, pass)
      block.call self
      @pop.finish
    end

    def each(&block)
      @pop.each do |popmail|
        block.call BlockMail.parse(popmail.pop)
      end
    end
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
      @cc      = []
      @bcc     = []
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

    def subject(val=nil)
      val ? @subject = val : @subject
    end

    def from(addr=nil, name=nil)
      addr ? @from = [addr, name] : @from
    end

    def to(addr=nil, name=nil)
      addr ? @to << [addr, name] : @to
    end

    def cc(addr=nil, name=nil)
      addr ? @cc << [addr, name] : @cc
    end

    def bcc(addr=nil, name=nil)
      addr ? @bcc << [addr, name] : @bcc
    end

    def body(val=nil)
      val ? @body = val : @body
    end

    def to_s
      ([
        'MIME-Version: 1.0',
        'Content-Type: text/plain; charset=' + @encoding,
        'From: ' + encode_addr(@from[0], @from[1]),
        @to.map do |val|
          'To: ' + encode_addr(val[0], val[1])
        end,
        @cc.map do |val|
          'Cc: ' + encode_addr(val[0], val[1])
        end,
        'Date: ' + Time.now.rfc2822,
        'Subject: ' + encode(@subject)
      ].flatten!.join("\n") + "\n\n" + @body).encode(@encoding)
    end

    def to_smtp
      [
        to_s.force_encoding('ASCII-8BIT'),
        @from[0],
        *((@to + @cc + @bcc).map do |v| v[0] end)
      ]
    end
  end
end
